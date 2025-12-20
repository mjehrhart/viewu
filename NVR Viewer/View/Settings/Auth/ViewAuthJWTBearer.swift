import SwiftUI

struct ViewAuthJWTBearer: View {

    let reloadConfig: () async -> Void

    let widthMultiplier: CGFloat = 4/5.8
    let api = APIRequester()

    @State private var scale = 1.0
    @State private var showBearer = false
    @FocusState private var isFocused: Bool
    @FocusState private var isAddressFocused: Bool
    
    @ObservedObject var nvrManager = NVRConfig.shared()

    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true

    @AppStorage("bearerIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("bearerPortAddress") private var nvrPortAddress: String = "5000"
    @AppStorage("bearerIsHttps") private var nvrIsHttps: Bool = true
    @AppStorage("bearerSecret") private var bearerSecret: String = ""

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

                TextField("5000", text: $nvrPortAddress)
                    .keyboardType(.numberPad)
//                    .focused($isFocused)
//                    .toolbar {
//                        ToolbarItemGroup(placement: .keyboard) {
//                            Spacer()
//                            Button("Done") { isFocused = false }
//                        }
//                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()

            // MARK: HTTPS toggle
            Toggle("Https", isOn: $nvrIsHttps)
                .tint(Color(red: 0.153, green: 0.69, blue: 1))

            Divider()

            // MARK: Secret (JWT)
            HStack(spacing: 8) {
                Text("Secret")
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if !showBearer {
                        SecureField("", text: $bearerSecret)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            TextField("secret goes here", text: $bearerSecret)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button("", systemImage: showBearer ? "eye.slash" : "eye") {
                    showBearer.toggle()
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

                    let host = normalizedHost(nvrIPAddress)
                    nvrIPAddress = host

                    // IMPORTANT: set profile first so subsequent setIP/setPort save to bearer keys
                    nvrManager.setAuthType(authType: .bearer)

                    nvrManager.setHttps(http: nvrIsHttps)
                    nvrManager.setIP(ip: host)
                    nvrManager.setPort(ports: nvrPortAddress)

                    nvrManager.connectionState = .disconnected

                    Task {
                        let urlString = buildURLString(isHttps: nvrIsHttps, host: host, port: nvrPortAddress)

                        do {
                            try await api.checkConnectionStatus(
                                urlString: urlString,
                                authType: .bearer
                            ) { _, error in

                                if let error = error {
                                    Log.error(
                                        page: "ViewAuthJWTBearer",
                                        fn: "Bearer Connection",
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
                                page: "ViewAuthJWTBearer",
                                fn: "Bearer Connection",
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
                        authType: .bearer
                    ) { _, error in
                        if let error = error {
                            Log.error(
                                page: "ViewAuthJWTBearer",
                                fn: "Bearer Connection",
                                "\(String(describing: error)) - \(urlString)"
                            )
                            nvrManager.connectionState = .disconnected
                            return
                        }
                        nvrManager.connectionState = .connected
                    }
                } catch {
                    Log.error(
                        page: "ViewAuthJWTBearer",
                        fn: "Bearer Connection",
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

