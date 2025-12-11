import SwiftUI

struct ViewAuthFrigate: View {
    
    let widthMultiplier:CGFloat = 4/5.8
    let api = APIRequester()
    
    @State private var scale = 1.0
    @State private var showBearer = false
    @State private var showPassword = false
    @State private var selectedRole: String = "viewer"
    
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var nvr = NVRConfig.shared()
    
    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    
    @AppStorage("frigateIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("frigatePortAddress") private var nvrPortAddress: String = "8971"
    @AppStorage("frigateIsHttps") private var nvrIsHttps: Bool = true
    @AppStorage("frigateBearerSecret") private var frigateBearerSecret: String = ""
    
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
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Divider()
            
            // MARK: Port
            HStack {
                Text("Port")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("8971", text: $nvrPortAddress)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        SecureField("", text: $frigateBearerSecret)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if showBearer {
                        ScrollView(.horizontal, showsIndicators: false) {
                            TextField("secret goes here", text: $frigateBearerSecret)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                Button("", systemImage: showBearer ? "eye.slash" : "eye") {
                    showBearer.toggle()
                } 
                .buttonStyle(.borderless)   // or .plain
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
                                Log.shared().print(
                                    page: "ViewAuthFrigate",
                                    fn: "NVR Connection",
                                    type: "ERROR",
                                    text: "\(String(describing: error)) - \(urlString)"
                                )
                                nvrManager.connectionState = .disconnected
                                return
                            }
                            nvrManager.connectionState = .connected
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
                        Log.shared().print(
                            page: "ViewAuthFrigate",
                            fn: "NVR Connection",
                            type: "ERROR",
                            text: "\(String(describing: error)) - \(urlString)"
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

#Preview {
    ViewAuthFrigate()
}
