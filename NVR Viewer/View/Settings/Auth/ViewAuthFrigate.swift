import SwiftUI

struct ViewAuthFrigate: View {

    let reloadConfig: () async -> Void

    let widthMultiplier: CGFloat = 4/5.8
    let api = APIRequester()

    @State private var scale = 1.0
    @State private var showBearer = false
    @FocusState private var isFocused: Bool
    @FocusState private var isAddressFocused: Bool
    
    @ObservedObject var nvrManager = NVRConfig.shared()

    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true

    @AppStorage("frigateIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("frigatePortAddress") private var nvrPortAddress: String = "8971"
    @AppStorage("frigateIsHttps") private var nvrIsHttps: Bool = true
    @AppStorage("frigateBearerSecret") private var frigateBearerSecret: String = ""
    @AppStorage("frigateUser") private var frigateUser: String = "admin"
    @AppStorage("frigatePassword") private var frigatePassword: String = ""
    @State private var showPassword = false

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
                    .multilineTextAlignment(.leading)
//                    .focused($isAddressFocused)
//                    .toolbar {
//                        ToolbarItemGroup(placement: .keyboard) {
//                            Spacer()
//                            Button("Done") { isAddressFocused = false }
//                        }
//                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            // MARK: Port
            HStack {
                Text("Port")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("8971", text: $nvrPortAddress)
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
            
            // CJ: Removed bearer to allow for username and password.

            Divider()

            HStack(spacing: 8) {
                Text("Username")
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Username", text: $frigateUser)
                    .autocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 8) {
                Text("Password")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if showPassword {
                        TextField("Password", text: $frigatePassword)
                            .autocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Password", text: $frigatePassword)
                            .autocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
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
            // CJ: Updated to clear cached token and to save credentials.
            HStack {
                Spacer()

                Button("Save Connection") {
                    let host = normalizedHost(nvrIPAddress)
                    let username = frigateUser.trimmingCharacters(in: .whitespacesAndNewlines)
                    let password = frigatePassword

                    nvrIPAddress = host
                    frigateUser = username

                    // IMPORTANT: set profile first so subsequent setIP/setPort save to the Frigate keys
                    nvrManager.setAuthType(authType: .frigate)

                    nvrManager.setHttps(http: nvrIsHttps)
                    nvrManager.setIP(ip: host)
                    nvrManager.setPort(ports: nvrPortAddress)

                    // Clear any old cached token so this save actually tests the new credentials
                    AuthFrigateLogin.shared.clearStoredToken()
                    AuthFrigateLogin.shared.saveCredentials(
                        username: username,
                        password: password
                    )

                    nvrManager.connectionState = .disconnected
                    // If you have a .connecting state, use that instead.

                    Task {
                        let urlString = buildURLString(
                            isHttps: nvrIsHttps,
                            host: host,
                            port: nvrPortAddress
                        )

                        do {
                            try await api.checkConnectionStatus(
                                urlString: urlString,
                                authType: .frigate
                            ) { _, error in
                                if let error = error {
                                    Log.error(
                                        page: "ViewAuthFrigate",
                                        fn: "Frigate Connection",
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
                                page: "ViewAuthFrigate",
                                fn: "Frigate Connection",
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
            // Do NOT write into NVRConfig here (it can save into the wrong profile).
            //nvrManager.connectionState = .disconnected

            /*
            let host = normalizedHost(nvrIPAddress)
            guard !host.isEmpty else { return }

            Task {
                let urlString = buildURLString(isHttps: nvrIsHttps, host: host, port: nvrPortAddress)

                do {
                    try await api.checkConnectionStatus(
                        urlString: urlString,
                        authType: .frigate
                    ) { _, error in
                        if let error = error {
                            Log.error(
                                page: "ViewAuthFrigate",
                                fn: "Frigate Connection",
                                "\(String(describing: error)) - \(urlString)"
                            )
                            nvrManager.connectionState = .disconnected
                            return
                        }
                        nvrManager.connectionState = .connected
                    }
                } catch {
                    Log.error(
                        page: "ViewAuthFrigate",
                        fn: "Frigate Connection",
                        "checkConnectionStatus threw: \(error) - \(urlString)"
                    )
                    nvrManager.connectionState = .disconnected
                }
            }
            */
        }
    }

    // CJ: Updated to exclude ':' from URL when there is no port specified
    private func buildURLString(isHttps: Bool, host: String, port: String) -> String {
        let scheme = isHttps ? "https://" : "http://"
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedPort.isEmpty {
            return "\(scheme)\(trimmedHost)"
        } else {
            return "\(scheme)\(trimmedHost):\(trimmedPort)"
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

