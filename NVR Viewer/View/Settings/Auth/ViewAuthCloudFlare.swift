import SwiftUI

private let appGroupDefaults: UserDefaults = UserDefaults(suiteName: "group.com.viewu.app") ?? .standard

struct ViewAuthCloudFlare: View {

    let reloadConfig: () async -> Void

    let widthMultiplier: CGFloat = 4/5.8
    let api = APIRequester()

    @State private var scale = 1.0
    @State private var showSecret = false

    @StateObject var nvrManager = NVRConfig.shared()

    @AppStorage("tipsSettingsNVR")
    private var tipsSettingsNVR: Bool = true

    @AppStorage("cloudFlareURLAddress")
    private var cloudFlareURLAddress: String = ""

    @AppStorage("cloudFlareClientId")
    private var cloudFlareClientId: String = ""

    @AppStorage("cloudFlareClientSecret")
    private var cloudFlareClientSecret: String = ""

    @AppStorage("cloudFlareSecret")
    private var legacyCloudFlareSecret: String = ""

    @Environment(\.colorScheme) var colorScheme

    var body: some View {

        VStack(spacing: 14) {

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

            HStack(spacing: 8) {
                Text("Client ID")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("client id goes here", text: $cloudFlareClientId)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 8) {
                Text("Secret")
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if !showSecret {
                        SecureField("", text: $cloudFlareClientSecret)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            TextField("secret goes here", text: $cloudFlareClientSecret)
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

            HStack {
                Spacer()

                Button("Save Connection") {

                    let hostOnly = normalizedHost(cloudFlareURLAddress)
                    if hostOnly.isEmpty {
                        Log.error(
                            page: "ViewAuthCloudFlare",
                            fn: "Save Connection",
                            "Refusing to save: Cloudflare host is empty. (This would produce https://:443 and break connection)"
                        )
                        return
                    }

                    // ✅ Persist normalized host
                    cloudFlareURLAddress = hostOnly

                    // ✅ NEW: Mirror host into App Group too (prevents https://:443 in early/background readers)
                    appGroupDefaults.set(hostOnly, forKey: "cloudFlareURLAddress")

                    let idTrim = cloudFlareClientId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let secretTrim = cloudFlareClientSecret.trimmingCharacters(in: .whitespacesAndNewlines)

                    nvrManager.setAuthType(authType: .cloudflare)
                    nvrManager.setHttps(http: true)
                    nvrManager.setIP(ip: hostOnly)
                    nvrManager.setPort(ports: "443")

                    // Keep your existing sync behavior
                    CloudflareAccessCreds.set(clientId: idTrim, clientSecret: secretTrim)
                    appGroupDefaults.set(idTrim, forKey: "cloudFlareClientId")
                    appGroupDefaults.set(secretTrim, forKey: "cloudFlareClientSecret")

                    _ = NotificationAuthShared.sync(
                        authTypeRaw: "cloudflare",
                        cloudFlareClientId: idTrim,
                        cloudFlareSecret: secretTrim
                    )

                    let rbHost = (appGroupDefaults.string(forKey: "cloudFlareURLAddress") ?? "")
                    let rbId = (appGroupDefaults.string(forKey: "cloudFlareClientId") ?? "")
                    let rbSecret = (appGroupDefaults.string(forKey: "cloudFlareClientSecret") ?? "")
                    Log.debug(
                        page: "ViewAuthCloudFlare",
                        fn: "Save Connection",
                        "[app] AppGroup readback suite=group.com.viewu.app hostLen=\(rbHost.count) idLen=\(rbId.count) secretLen=\(rbSecret.count)"
                    )

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
            nvrManager.connectionState = .disconnected

            // ✅ NEW: Restore host from App Group if Standard is empty (prevents https://:443)
            if cloudFlareURLAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let agHost = (appGroupDefaults.string(forKey: "cloudFlareURLAddress") ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !agHost.isEmpty {
                    cloudFlareURLAddress = agHost
                    Log.debug(page: "ViewAuthCloudFlare", fn: "onAppear", "Restored cloudFlareURLAddress from App Group")
                }
            }

            if cloudFlareClientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !legacyCloudFlareSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cloudFlareClientSecret = legacyCloudFlareSecret
                Log.debug(page: "ViewAuthCloudFlare", fn: "onAppear", "Migrated legacy cloudFlareSecret -> cloudFlareClientSecret (standard)")
            }

            let idTrim = cloudFlareClientId.trimmingCharacters(in: .whitespacesAndNewlines)
            let secretTrim = cloudFlareClientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
            if !idTrim.isEmpty { appGroupDefaults.set(idTrim, forKey: "cloudFlareClientId") }
            if !secretTrim.isEmpty { appGroupDefaults.set(secretTrim, forKey: "cloudFlareClientSecret") }

            // ✅ Mirror host too
            let hostOnly = normalizedHost(cloudFlareURLAddress)
            if !hostOnly.isEmpty { appGroupDefaults.set(hostOnly, forKey: "cloudFlareURLAddress") }

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

    private func normalizedHost(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if let url = URL(string: trimmed), let host = url.host, !host.isEmpty {
            return host
        }
        if let url = URL(string: "https://\(trimmed)"), let host = url.host, !host.isEmpty {
            return host
        }

        let noScheme = trimmed
            .replacingOccurrences(of: "https://", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "http://", with: "", options: [.caseInsensitive])

        let hostPort = noScheme.split(separator: "/").first.map(String.init) ?? noScheme
        let hostOnly = hostPort.split(separator: ":").first.map(String.init) ?? hostPort
        return hostOnly
    }
}
