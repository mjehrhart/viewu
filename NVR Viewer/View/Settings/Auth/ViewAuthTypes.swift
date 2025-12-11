import SwiftUI

struct ViewAuthTypes: View {
    
    let widthMultiplier:CGFloat = 4/5.8
    let api = APIRequester()
    let bColor = Color(red: 0.153, green: 0.69, blue: 1)
    
    @State private var scale = 1.0
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var nvr = NVRConfig.shared()
    
    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    
    var body : some View {
        
        VStack(spacing: 10) {
            
            // Auth type selector – four equal-width buttons, no scroll bar
            HStack(spacing: 2) {
                
                authButton(title: "None", type: .none)
                authButton(title: "Bearer", type: .bearer)
                authButton(title: isLandscape ? "CloudFlare" : "CF", type: .cloudflare) 
                    .onRotate { orientation in
                        if orientation.isValidInterfaceOrientation {
                            isLandscape = orientation.isLandscape
                        }
                    }
                authButton(title: "Frigate", type: .frigate)
            }
            // Let the form/section handle most of the padding
            .padding(.top, 4)
            
            // Keep exactly the same logic for which settings view to show
            if nvr.getAuthType() == .none  {
                ViewAuthNone()
            }
            if nvr.getAuthType() == .bearer  {
                ViewAuthJWTBearer()
            }
            if nvr.getAuthType() == .cloudflare  {
                ViewAuthCloudFlare()
            }
            if nvr.getAuthType() == .frigate {
                ViewAuthFrigate()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper
    
    @ViewBuilder
    private func authButton(title: String, type: AuthType) -> some View {
        Button(action: {
            nvr.setAuthType(authType: type)
            authType = type
        }) {
            Text(title)
                .frame(maxWidth: .infinity)    // share row width evenly
        }
        .buttonStyle(.bordered)
        .foregroundStyle(nvr.getAuthType() == type ? .orange : bColor)
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
            .background(Color.indigo.opacity(0.2))
            .cornerRadius(8)
            .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 2)
            .foregroundColor(.indigo)
            .padding()
    }
}

#Preview {
    ViewAuthTypes()
}
