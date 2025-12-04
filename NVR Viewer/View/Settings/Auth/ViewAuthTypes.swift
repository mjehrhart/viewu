//
//  ViewAuthTypes.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/2/25.
//

import SwiftUI

struct ViewAuthTypes: View {
    
    let widthMultiplier:CGFloat = 4/5.8
    let api = APIRequester()
    let bColor = Color(red: 0.153, green: 0.69, blue: 1);
    
    @State private var scale = 1.0
    
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var nvr = NVRConfig.shared()
    
    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
 
    var body : some View {
 
        VStack {
            ControlGroup() {
                HStack(spacing: 2) {
                    Button(action: {
                        nvr.setAuthType(authType: .none)
                        authType = .none
                    }) {
                        Text("None")
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(nvr.getAuthType() == .none ? .orange : bColor)
                    //.frame(maxWidth: .infinity)
                    
                    Button(action: {
                        nvr.setAuthType(authType: .bearer)
                        authType = .bearer
                    }) {
                        Text("JWT Bearer")
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(nvr.getAuthType() == .bearer ? .orange : bColor)
                    //.frame(maxWidth: .infinity)
 
                    Button(action: {
                        nvr.setAuthType(authType: .cloudflare)
                        authType = .cloudflare
                    }) {
                        Text("CloudFlare")
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(nvr.getAuthType() == .cloudflare ? .orange : bColor)
                    //.frame(maxWidth: .infinity)
                    
                    Button("Frigate") {
                        nvr.setAuthType(authType: .frigate)
                        authType = .frigate
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(nvr.getAuthType() == .frigate ? .orange : bColor)
                    //.frame(maxWidth: .infinity)
                }
                 
            }
            .padding(.leading, 23)
            .padding(.trailing, 23)
            .frame(maxWidth: .infinity)
            .controlGroupStyle(.automatic)
            
            if nvr.getAuthType() == .none  {
                ViewAuthNone()
            }
            if nvr.getAuthType() == .bearer  {
                ViewAuthJWTBearer() 
            }
            if nvr.getAuthType() == .cloudflare  {
                VStack {
                    Text("CloudFlare")
                    Text("This is in development")
                }
            } 
            if nvr.getAuthType() == .frigate {
                ViewAuthFrigate()
            }
            
        }
    } 
}

struct CustomPressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(configuration.isPressed ? Color.gray : Color.orange.opacity(0.6))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

struct CoolControlGroupStyle: ControlGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .padding(5)
            .background(Color.indigo.opacity(0.2)) // A subtle, cool background
            .cornerRadius(8)
            .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 2) // A cool shadow
            .foregroundColor(.indigo) // Cool text color
            .padding()
    }
}

#Preview {
    ViewAuthTypes()
}
