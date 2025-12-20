import SwiftUI

struct ViewAuthNone: View {

    let reloadConfig: () async -> Void

    let widthMultiplier: CGFloat = 4/5.8
    let api = APIRequester()

    @State private var scale = 1.0
    @FocusState private var isFocused: Bool
    @FocusState private var isAddressFocused: Bool
    
    @ObservedObject var nvrManager = NVRConfig.shared()

    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    @AppStorage("nvrIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("nvrPortAddress") private var nvrPortAddress: String = "5000"
    @AppStorage("nvrIsHttps") private var nvrIsHttps: Bool = true

    @Environment(\.colorScheme) var colorScheme

    var body: some View {

        VStack(spacing: 14) {

            // MARK: Address
            HStack {
                Text("Address")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("0.0.0.0", text: $nvrIPAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
//                    .focused($isAddressFocused)
//                    .toolbar {
//                        ToolbarItemGroup(placement: .keyboard) {
//                            Spacer()
//                            Button("Done") { isAddressFocused = false }
//                        }
//                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // MARK: Port
            HStack {
                Text("Port")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("5000", text: $nvrPortAddress)
                    .keyboardType(.numberPad)
//                    .focused($isFocused)
//                    .toolbar {
//                        ToolbarItemGroup(placement: .keyboard) {
//                            Spacer()
//                            Button("Done") { isFocused = false }
//                        }
//                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // MARK: HTTPS toggle
            Toggle("Https", isOn: $nvrIsHttps)
                .tint(Color(red: 0.153, green: 0.69, blue: 1))

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

                    let host = normalizedHost(nvrIPAddress)
                    nvrIPAddress = host

                    // IMPORTANT: set profile first
                    nvrManager.setAuthType(authType: .none)

                    nvrManager.setHttps(http: nvrIsHttps)
                    nvrManager.setIP(ip: host)
                    nvrManager.setPort(ports: nvrPortAddress)

                    nvrManager.connectionState = .disconnected

                    Task {
                        let urlString = buildURLString(isHttps: nvrIsHttps, host: host, port: nvrPortAddress)

                        do {
                            try await api.checkConnectionStatus(
                                urlString: urlString,
                                authType: .none
                            ) { _, error in

                                if let error = error {
                                    Log.error(
                                        page: "ViewAuthNone",
                                        fn: "NVR Connection",
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
                                page: "ViewAuthNone",
                                fn: "NVR Connection",
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
        .background(.background)
        .cornerRadius(25)
        .onAppear {
            // Do NOT write into NVRConfig here.
            //nvrManager.connectionState = .disconnected

            /*
            let host = normalizedHost(nvrIPAddress)
            guard !host.isEmpty else { return }

            Task {
                let urlString = buildURLString(isHttps: nvrIsHttps, host: host, port: nvrPortAddress)

                do {
                    try await api.checkConnectionStatus(
                        urlString: urlString,
                        authType: .none
                    ) { _, error in

                        if let error = error {
                            Log.error(
                                page: "ViewAuthNone",
                                fn: "NVR Connection",
                                "\(String(describing: error)) - \(urlString)"
                            )
                            nvrManager.connectionState = .disconnected
                            return
                        }

                        nvrManager.connectionState = .connected
                    }
                } catch {
                    Log.error(
                        page: "ViewAuthNone",
                        fn: "NVR Connection",
                        "checkConnectionStatus threw: \(error) - \(urlString)"
                    )
                    nvrManager.connectionState = .disconnected
                }
            }
            */
        }
    }

    private func buildURLString(isHttps: Bool, host: String, port: String) -> String {
        let scheme = isHttps ? "https://" : "http://"
        return "\(scheme)\(host):\(port)"
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

