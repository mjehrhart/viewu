import SwiftUI

struct ViewAuthNone: View {
    
    let reloadConfig: () async -> Void
    
    let widthMultiplier:CGFloat = 4/5.8
    let api = APIRequester()
    
    @State private var scale = 1.0
    
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var nvr = NVRConfig.shared()
    
    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    @AppStorage("nvrIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("nvrPortAddress") private var nvrPortAddress: String = "5000"
    @AppStorage("nvrIsHttps") private var nvrIsHttps: Bool = true
    
    @Environment(\.colorScheme) var colorScheme   // .light or .dark
    
    var body: some View {
        
        VStack(spacing: 14) {
            
            // MARK: Address
            HStack {
                Text("Address")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("0.0.0.0", text: $nvrIPAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // MARK: Port
            HStack {
                Text("Port")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("5000", text: $nvrPortAddress)
                    .keyboardType(.numberPad)
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
                    // Sync data across view and model
                    nvrManager.setHttps(http: nvrIsHttps)
                    nvrManager.setIP(ip: nvrIPAddress)
                    nvrManager.setPort(ports: nvrPortAddress)

                    // Reset connection state while we test
                    nvrManager.connectionState = .disconnected

                    Task {
                        let urlString = nvr.getUrl()

                        do {
                            try await api.checkConnectionStatus(
                                urlString: urlString,
                                authType: nvr.getAuthType()
                            ) { data, error in

                                if let error = error {
                                    Log.error(
                                        page: "ViewAuthNone",
                                        fn: "NVR Connection", "\(String(describing: error)) - \(urlString)"
                                    )
                                    nvrManager.connectionState = .disconnected
                                    return
                                }

                                // Success
                                nvrManager.connectionState = .connected

                                // Fire off the async reload without making this closure async
                                Task {
                                    await reloadConfig()
                                }
                            }
                        } catch {
                            Log.error(
                                page: "ViewAuthNone",
                                fn: "NVR Connection", "checkConnectionStatus threw: \(error) - \(urlString)"
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
            // Sync data across view and model
            nvrManager.setHttps(http: nvrIsHttps )
            nvrManager.setIP(ip: nvrIPAddress )
            nvrManager.setPort( ports: nvrPortAddress )
            
            nvrManager.connectionState = .disconnected
            
            Task {
                let url = nvr.getUrl()
                let urlString = url
                try await api.checkConnectionStatus(
                    urlString: urlString,
                    authType: nvr.getAuthType()
                ) { (data, error) in
                    
                    if let error = error { 
                        Log.error(
                            page: "ViewAuthNone",
                            fn: "NVR Connection", "\(String(describing: error)) - \(urlString)"
                        )
                        nvrManager.connectionState = .disconnected
                        return
                    }
                    nvrManager.connectionState = .connected 
                }
            }
        }
    }
}
 
