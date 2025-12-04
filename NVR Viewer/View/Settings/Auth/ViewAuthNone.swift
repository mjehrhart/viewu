//
//  ViewAuthFrigate.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/3/25.
//

import SwiftUI

struct ViewAuthNone: View {
    
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
    
    var body: some View {
        
        VStack{
            GeometryReader{ geometry in
 
                List {
                    
                    HStack{
                        Text("Address")
                            .frame(width:(geometry.size.width/2) - 55, alignment: .leading)
                            .padding(.leading, 25)
                            //.border(.gray, width: 2)
                        
                        //ScrollView(.horizontal){
                            TextField("0.0.0.0", text: $nvrIPAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .frame(width:(geometry.size.width/2) - 30, alignment: .trailing)
                        //}
                    }
                    .frame(width:geometry.size.width - 60, alignment: .leading)
                    
                    HStack{
                        Text("Port")
                            .frame(width:(geometry.size.width/2) - 55, alignment: .leading)
                            .padding(.leading, 25)
                            //.border(.gray, width: 2)
                        TextField("5000", text: $nvrPortAddress)
                            .frame(width:(geometry.size.width/2) - 30, alignment: .trailing)
                    }
                    .frame(width:geometry.size.width - 60, alignment: .leading)
                    
                    Toggle("Https", isOn: $nvrIsHttps)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                        .padding(.leading, 25)
                        .frame(width:geometry.size.width - 60, alignment: .leading)
                    
                    Label(nvrManager.getConnectionState() ? "Connected" : "Disconnected", systemImage: "cable.connector")
                        .frame(width: geometry.size.width - 60, alignment: .trailing)
                        .foregroundStyle(nvrManager.getConnectionState() ? Color(red: 0.153, green: 0.69, blue: 1) : .red)
                    
                    Button("Save Connection") {
                        //Sync data accross view and model
                        nvrManager.setHttps(http: nvrIsHttps )
                        nvrManager.setIP(ip: nvrIPAddress )
                        nvrManager.setPort( ports: nvrPortAddress )
                        
                        Task {
                            let url = nvr.getUrl()
                            let urlString = url
                            try await api.checkConnectionStatus(urlString: urlString, authType: nvr.getAuthType()) { (data, error) in
                                
                                if let error = error {
                                    print("\(error.localizedDescription)")
                                    Log.shared().print(page: "ViewSetting", fn: "NVR Connection", type: "ERROR", text: "\(String(describing: error))")
                                    nvrManager.connectionState = .disconnected
                                    return
                                }
                                nvrManager.connectionState = .connected
                            }
                        }
                    }
                    //.buttonStyle(.bordered)
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: geometry.size.width - 50, alignment: .trailing)
                }
                .listStyle(.plain)
                .frame(width: geometry.size.width, alignment: .leading)
                .cornerRadius(25)
                .onAppear{
                    //Sync data accross view and model
                    nvrManager.setHttps(http: nvrIsHttps )
                    nvrManager.setIP(ip: nvrIPAddress )
                    nvrManager.setPort( ports: nvrPortAddress )
                    
                    Task {
                        let url = nvr.getUrl()
                        let urlString = url
                        try await api.checkConnectionStatus(urlString: urlString, authType: nvr.getAuthType()) { (data, error) in
                            
                            if let error = error {
                                print("\(error.localizedDescription)")
                                Log.shared().print(page: "ViewSetting", fn: "NVR Connection", type: "ERROR", text: "\(String(describing: error))")
                                nvrManager.connectionState = .disconnected
                                return
                            }
                            nvrManager.connectionState = .connected
                        }
                    }
                }
                
            }
            //.background(.green)
            .cornerRadius(25)
            
        }
        .frame(height: 230, alignment: .topLeading)
        //.background(.red)
        .cornerRadius(25)
    }
}

#Preview {
    ViewAuthNone()
}
