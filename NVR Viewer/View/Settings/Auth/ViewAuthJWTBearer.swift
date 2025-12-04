//
//  ViewAuthJWTBearer.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/3/25.
//

import SwiftUI

struct ViewAuthJWTBearer: View {
    
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
    
    @AppStorage("bearerIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("bearerPortAddress") private var nvrPortAddress: String = "5000"
    @AppStorage("bearerIsHttps") private var nvrIsHttps: Bool = true
    @AppStorage("bearerSecret") private var bearerSecret: String = ""
//    @AppStorage("bearerUserRole") private var bearerUserRole: String = "admin"
//    @AppStorage("bearerUser") private var bearerUser: String = "admin"
//    @AppStorage("bearerPassword") private var bearerPassword: String = ""
    
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
                        TextField("8971", text: $nvrPortAddress)
                            .frame(width:(geometry.size.width/2) - 30, alignment: .trailing)
                    }
                    .frame(width:geometry.size.width - 60, alignment: .leading)
                    
                    Toggle("Https", isOn: $nvrIsHttps)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                        .padding(.leading, 25)
                        .frame(width:geometry.size.width - 60, alignment: .leading)
                     
                    /*
                    HStack{
                        Text("Role")
                            .frame(width:(geometry.size.width/2) - 55, alignment: .leading)
                            .padding(.leading, 25)
                        Menu {
                            Button("Viewer") { selectedRole = "viewer" }
                            Button("Admin") { selectedRole = "admin" }
                        } label: {
                            Text(selectedRole)
                            Image(systemName: "chevron.down")
                        }
                        .onChange(of: selectedRole) { newValue in
                            //print("changed = \(newValue)")
                            frigateUserRole = newValue
                        }
                        .frame(width:(geometry.size.width/2) - 30, alignment: .trailing)
                    }
                    .frame(width:geometry.size.width - 60, alignment: .leading)
                    */
                    
                    HStack{
                        VStack{
                            HStack{
                                
                                Text("Secret")
                                    .frame(width:(geometry.size.width/2) - 55, alignment: .leading)
                                    .padding(.leading, 25)
                                
                                ZStack {
                                    
                                    if !showBearer {
                                        SecureField("", text: $bearerSecret)
                                            .frame(alignment: .leading)
                                    }
                                    
                                    if showBearer {
                                        ScrollView(.horizontal) {
                                            TextField("secret goes here", text: $bearerSecret)
                                                .frame(width:(geometry.size.width/2) - 30, alignment: .leading)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button("", systemImage: showBearer ? "eye.slash" : "eye") {
                                    showBearer = !showBearer
                                }
                                .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                                .frame(alignment: .trailing)
                                .padding(.trailing, 40)
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    }
                    .frame(width:geometry.size.width - 60, alignment: .leading)
                        
                    /*
                    VStack{
                        HStack{
                            Text("User")
                                .frame(width:(geometry.size.width/2) - 55, alignment: .leading)
                                .padding(.leading, 45)
                            TextField("", text: $bearerUser)
                                .frame(alignment: .leading)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        
                        HStack{
                            
                            Text("Password")
                                .frame(width:(geometry.size.width/2) - 55, alignment: .leading)
                                .padding(.leading, 45)
                            
                            ZStack {
                                
                                if !showPassword {
                                    SecureField("", text: $bearerPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .frame(alignment: .leading)
                                }
                                
                                if showPassword {
                                    TextField("", text: $bearerPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .frame(alignment: .leading)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button("", systemImage: showPassword ? "eye.slash" : "eye") {
                                showPassword = !showPassword
                            }
                            .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                            .frame(alignment: .trailing)
                            .padding(.trailing, 20)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    */
                    
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
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: geometry.size.width - 50, alignment: .trailing)
                }
                .listStyle(.plain)
                .frame(width: geometry.size.width, alignment: .leading)
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
        }
        .frame(height: 275, alignment: .topLeading) //350 for everything
        .cornerRadius(25)
    }
}
//#Preview {
//    ViewAuthJWTBearer()
//}
