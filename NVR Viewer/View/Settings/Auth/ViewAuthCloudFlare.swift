//
//  ViewAuthCloudFlare.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/10/25.
//

import SwiftUI

struct ViewAuthCloudFlare: View {
    
    let widthMultiplier:CGFloat = 4/5.8
    let api = APIRequester()
    
    @State private var scale = 1.0
    @State private var showId = false
    @State private var showSecret = false
    
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var nvr = NVRConfig.shared()
    
    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    
    @AppStorage("cloudFlareURLAddress") private var cloudFlareURLAddress: String = ""
    @AppStorage("cloudFlareClientId") private var cloudFlareClientId: String = ""
    @AppStorage("cloudFlareSecret") private var cloudFlareSecret: String = ""
    
    @Environment(\.colorScheme) var colorScheme   // .light or .dark
    
    var body: some View {
        
        VStack(spacing: 14) {
            
            // MARK: Address
            HStack {
                Text("Address")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("cloudflare domain only", text: $cloudFlareURLAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
             
            Divider()
            
            // MARK: Client ID
            HStack(spacing: 8) {
                Text("Client ID")
                    .frame(maxWidth: .infinity, alignment: .leading)
         
                TextField("client id goes here", text: $cloudFlareClientId)
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
                    }
                    
                    if showSecret {
                        ScrollView(.horizontal, showsIndicators: false) {
                            TextField("secret goes here", text: $cloudFlareSecret)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                Button("", systemImage: showSecret ? "eye.slash" : "eye") {
                    showSecret.toggle()
                }
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
                    nvrManager.setHttps(http: true )
                    nvrManager.setIP(ip: cloudFlareURLAddress )
                    nvrManager.setPort( ports: "443" )

                    // NEW: clear previous status so you don't see a stale "Connected"
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
                                    page: "ViewAuthCloudFlare",
                                    fn: "CloudFlare Connection",
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
            nvrManager.setHttps(http: true )
            nvrManager.setIP(ip: cloudFlareURLAddress )
            nvrManager.setPort( ports: "443" )
            
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
                            page: "ViewAuthCloudFlare",
                            fn: "CloudFlare Connection",
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
    ViewAuthCloudFlare()
}
