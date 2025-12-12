//
//  ViewAuthCloudFlare.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/10/25.
//

import SwiftUI

struct ViewAuthCloudFlare: View {

    let reloadConfig: () async -> Void

    let widthMultiplier: CGFloat = 4/5.8
    let api = APIRequester()

    @State private var scale = 1.0
    @State private var showSecret = false

    @StateObject var nvrManager = NVRConfig.shared()

    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true

    @AppStorage("cloudFlareURLAddress") private var cloudFlareURLAddress: String = ""
    @AppStorage("cloudFlareClientId") private var cloudFlareClientId: String = ""
    @AppStorage("cloudFlareSecret") private var cloudFlareSecret: String = ""

    @Environment(\.colorScheme) var colorScheme

    var body: some View {

        VStack(spacing: 14) {

            // MARK: Address
            HStack {
                Text("Address")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("cloudflare domain only", text: $cloudFlareURLAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // MARK: Client ID
            HStack(spacing: 8) {
                Text("Client ID")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("client id goes here", text: $cloudFlareClientId)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // MARK: Secret
            HStack(spacing: 8) {
                Text("Secret")
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if !showSecret {
                        SecureField("", text: $cloudFlareSecret)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            TextField("secret goes here", text: $cloudFlareSecret)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                Button("", systemImage: showSecret ? "eye.slash" : "eye") {
                    showSecret.toggle()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
            }

            Divider()

            // MARK: Connection status
            Label(
                nvrManager.getConnectionState() ? "Connected" : "Disconnected",
                systemImage: "cable.connector"
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .foregroundStyle(
                nvrManager.getConnectionState()
                ? Color(red: 0.153, green: 0.69, blue: 1)
                : .red
            )

            // MARK: Save button
            HStack {
                Spacer()

                Button("Save Connection") {
                    // Normalize "Address" into a host (prevents accidental "https://https://..." issues)
                    let hostOnly = normalizedHost(cloudFlareURLAddress)
                    cloudFlareURLAddress = hostOnly

                    // Activate Cloudflare profile first
                    nvrManager.setAuthType(authType: .cloudflare)

                    // Save profile values into the Cloudflare profile
                    nvrManager.setHttps(http: true)
                    nvrManager.setIP(ip: hostOnly)
                    nvrManager.setPort(ports: "443")

                    // Sync to App Group explicitly so NotificationExtension can fetch images
                    _ = NotificationAuthShared.sync(
                        authTypeRaw: "cloudflare",
                        cloudFlareClientId: cloudFlareClientId.trimmingCharacters(in: .whitespacesAndNewlines),
                        cloudFlareSecret: cloudFlareSecret.trimmingCharacters(in: .whitespacesAndNewlines)
                    )

                    Log.debug(
                        page: "ViewAuthCloudFlare",
                        fn: "Save Connection",
                        "[app] synced App Group \(NotificationAuthShared.suiteName) idLen=\(cloudFlareClientId.count) secretLen=\(cloudFlareSecret.count)"
                    )

                    // Clear previous status so you don't see stale "Connected"
                    nvrManager.connectionState = .disconnected

                    Task {
                        let urlString = nvrManager.getUrl()

                        do {
                            try await api.checkConnectionStatus(
                                urlString: urlString,
                                authType: nvrManager.getAuthType()
                            ) { _, error in

                                if let error = error {
                                    Log.error(
                                        page: "ViewAuthCloudFlare",
                                        fn: "CloudFlare Connection",
                                        "\(String(describing: error)) - \(urlString)"
                                    )
                                    nvrManager.connectionState = .disconnected
                                    return
                                }

                                nvrManager.connectionState = .connected
                                Task { await reloadConfig() }
                            }
                        } catch {
                            Log.error(
                                page: "ViewAuthCloudFlare",
                                fn: "CloudFlare Connection",
                                "checkConnectionStatus threw: \(error) - \(urlString)"
                            )
                            nvrManager.connectionState = .disconnected
                        }
                    }
                }
                .buttonStyle(CustomPressEffectButtonStyle())
                .tint(Color(white: 0.58))
                .scaleEffect(scale)
                .animation(.linear(duration: 1), value: scale)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
        .cornerRadius(25)
        .onAppear {
            // Do not write profile values here — it can save into the wrong profile.
            nvrManager.connectionState = .disconnected

            // Optional: auto-check if user has a host configured
            let hostOnly = normalizedHost(cloudFlareURLAddress)
            guard !hostOnly.isEmpty else { return }

            Task {
                let urlString = "https://\(hostOnly):443"
                do {
                    try await api.checkConnectionStatus(
                        urlString: urlString,
                        authType: .cloudflare
                    ) { _, error in
                        if let error = error {
                            Log.error(
                                page: "ViewAuthCloudFlare",
                                fn: "CloudFlare Connection",
                                "\(String(describing: error)) - \(urlString)"
                            )
                            nvrManager.connectionState = .disconnected
                            return
                        }
                        nvrManager.connectionState = .connected
                    }
                } catch {
                    Log.error(
                        page: "ViewAuthCloudFlare",
                        fn: "CloudFlare Connection",
                        "checkConnectionStatus threw: \(error) - \(urlString)"
                    )
                    nvrManager.connectionState = .disconnected
                }
            }
        }
    }

    /// Converts anything the user pastes into a clean host:
    /// - "https://example.com" -> "example.com"
    /// - "example.com:443/path" -> "example.com"
    /// - "example.com" -> "example.com"
    private func normalizedHost(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // If it's a full URL, parse host.
        if let url = URL(string: trimmed), let host = url.host, !host.isEmpty {
            return host
        }

        // If it has no scheme, try adding https://
        if let url = URL(string: "https://\(trimmed)"), let host = url.host, !host.isEmpty {
            return host
        }

        // Fallback: strip scheme manually, strip path, strip port
        let noScheme = trimmed
            .replacingOccurrences(of: "https://", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "http://", with: "", options: [.caseInsensitive])

        let hostPort = noScheme.split(separator: "/").first.map(String.init) ?? noScheme
        let hostOnly = hostPort.split(separator: ":").first.map(String.init) ?? hostPort
        return hostOnly
    }
}

