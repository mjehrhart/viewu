//
//  ViewSettings.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import TipKit

struct ViewSettings: View {
    
    let title: String
  
    @StateObject var notificationManager = NotificationManager()
    
    var currentAppState = MQTTAppState()
    
    @StateObject var mqttManager = MQTTManager.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    
    @State private var scale = 1.0
    @State private var showingAlert = false
    @State private var showPassword = false
    
    @AppStorage("nvrIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("nvrPortAddress") private var nvrPortAddress: String = "5000"
    @AppStorage("nvrIsHttps") private var nvrIsHttps: Bool = true
    
    @AppStorage("developerModeIsOn") private var developerModeIsOn: Bool = false
    @AppStorage("notificationModeIsOn") private var notificationModeIsOn: Bool = false
    
    @AppStorage("frigatePlusOn") private var frigatePlusOn: Bool = false
    
    @AppStorage("cameraSubStream") private var cameraSubStream: Bool = false
    @AppStorage("cameraRTSPPath") private var cameraRTSPPath: Bool = false
    @AppStorage("camerGo2Rtc") private var camerGo2Rtc: Bool = true
    @AppStorage("cameraHLS") private var cameraHLS: Bool = false
    
    @AppStorage("mqttIPAddress") private var mqttIPAddress: String = ""
    @AppStorage("mqttPortAddress") private var mqttPortAddress: String = "1883"
    @AppStorage("mqttIsAnonUser") private var mqttIsAnonUser: Bool = true
    @AppStorage("mqttUser") private var mqttUser: String = ""
    @AppStorage("mqttPassword") private var mqttPassword: String = ""
     
    @AppStorage("isOnboarding") var isOnboarding: Bool?
    @AppStorage("tipsSettingsPairDevice") private var tipsSettingsPairDevice: Bool = true
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true
    @AppStorage("tipsNotificationTemplate") private var tipsNotificationTemplate: Bool = true
    @AppStorage("tipsNotificationDomain") private var tipsNotificationDomain: Bool = true
    @AppStorage("tipsNotificationDefault") private var tipsNotificationDefault: Bool = true
    @AppStorage("tipsLiveCameras") private var tipsLiveCameras: Bool = true
 
    //FIX THIS
    //11/05/2025 
    var fcm: String = UserDefaults.standard.string(forKey: "fcm") ?? "0"
    
    @AppStorage("viewu_device_paired") private var viewuDevicePairedArg: Bool = false
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
    @AppStorage("frigateVersion") private var frigateVersion: String = "0.0-0"
    
    @StateObject var nts = NotificationTemplateString.shared()
    
    let widthMultiplier:CGFloat = 2/5.8
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    var body: some View {

        ZStack {
            
            Form {
                
                Section{
                    Toggle("Enabled", isOn: $frigatePlusOn)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                } header: {
                    Text("Frigate+")
                        .foregroundColor(.orange)
                }
                
                Section{
                    Toggle("Enabled", isOn: $notificationModeIsOn)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                } header: {
                    Text("Notification Manager")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                  
                Section {
                    Toggle("RTSP", isOn: $camerGo2Rtc)
                        .onChange(of: camerGo2Rtc) {
                            if camerGo2Rtc == true {
                                cameraRTSPPath = false
                                cameraHLS = false
                            } else {
                                cameraHLS = true
                            }
                        }
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
//                    Toggle("RTSP", isOn: $cameraRTSPPath)
//                        .onChange(of: cameraRTSPPath) {
//                            if cameraRTSPPath == true {
//                                camerGo2Rtc = false
//                                cameraHLS = false
//                            }
//                        }
                    //.tint(Color(red: 0.153, green: 0.69, blue: 1))
                    Toggle("HLS", isOn: $cameraHLS)
                        .onChange(of: cameraHLS) {
                            if cameraHLS == true {
                                camerGo2Rtc = false
                                cameraRTSPPath = false
                                cameraSubStream = false
                            }
                            else {
                                camerGo2Rtc = true
                            }
                        }
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    Toggle("Use Sub Stream", isOn: $cameraSubStream)
                        .onChange(of: cameraSubStream) {
                            if cameraSubStream == true {
                                cameraHLS = false
                                camerGo2Rtc = true
                            }
                        }
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                } header: {
                    Text("Camera Stream")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section {
                    HStack{
                        Text("Broker Address:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        TextField("0.0.0.0", text: $mqttIPAddress)
                            .autocorrectionDisabled()
                            .frame(alignment: .leading) 
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)

                    HStack{
                        Text("Port:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        TextField("1883", text: $mqttPortAddress)
                            .frame(alignment: .leading)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)

                    HStack{
                        Text("Topic:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("viewu/pairing")
                            .frame(alignment: .leading)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    if developerModeIsOn {
                        HStack{
                            Text("")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            Text("frigate/events")
                                .frame(alignment: .leading)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    }
                    
                    Toggle("Anonymous", isOn: $mqttIsAnonUser)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
 
                    if !mqttIsAnonUser {
                        VStack{
                            HStack{
                                Text("User:")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                TextField("", text: $mqttUser)
                                    .frame(alignment: .leading)
                                    .disabled(mqttIsAnonUser)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                            HStack{
                                Text("Password:")
                                    //.frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .frame(width:150, alignment: .leading)
                                    .padding(.leading, 40)
                                 
                                ZStack {
                                    
                                    if !showPassword {
                                        SecureField("", text: $mqttPassword)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                            .frame(alignment: .leading)
                                            .disabled(mqttIsAnonUser)
                                    }
                                    
                                    if showPassword {
                                        TextField("", text: $mqttPassword)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                            .frame(alignment: .leading)
                                            .disabled(mqttIsAnonUser)
                                    }
                                }
                                
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
                    }
                    
                    Label(mqttManager.isConnected() ? "Connected" : "Disconnected", systemImage: "cable.connector")
                        .frame(width: UIScreen.screenWidth - 70, alignment: .trailing)
                        .foregroundStyle(mqttManager.isConnected() ? Color(red: 0.153, green: 0.69, blue: 1) : .red)
                    
                    Button("Save Connection") {
                        
                        //Sync data accross view and model
                        mqttManager.setAnonymous(anonymous: mqttIsAnonUser )
                        mqttManager.setIP(ip: mqttIPAddress )
                        mqttManager.setPort( port: mqttPortAddress )
                        mqttManager.setCredentials(user: mqttUser, password: mqttPassword)
                        
                        //connect to mqtt broker
                        mqttManager.initializeMQTT()
                        mqttManager.connect()
                    }
                    //.buttonStyle(.bordered)
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                     
                } header: {
                    Text("MQTT Settings")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                   
                Section {
                    
                    ViewTipsSettingsNVR(title: "Connection Requirements", message: "For optimal security, Viewu requires a secured HTTPS connection. HTTP is supported only for devices on your local network. To ensure encrypted communication and protect your video data, configure your server to use HTTPS whenever accessible outside your LAN.")
                    
                    HStack{
                        Text("Address:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            TextField("0.0.0.0", text: $nvrIPAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .frame(alignment: .leading)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    HStack{
                        Text("Port:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        TextField("5000", text: $nvrPortAddress)
                            .frame(alignment: .leading)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    Toggle("Https", isOn: $nvrIsHttps)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
//                    LabeledContent("NVR Synced", value: "No")
                     
                    Label(nvrManager.getConnectionState() ? "Connected" : "Disconnected", systemImage: "cable.connector")
                        .frame(width: UIScreen.screenWidth - 70, alignment: .trailing)
                        .foregroundStyle(nvrManager.getConnectionState() ? Color(red: 0.153, green: 0.69, blue: 1) : .red)
                    
                    Button("Save Connection") {
                        //Sync data accross view and model
                        nvrManager.setHttps(http: nvrIsHttps )
                        nvrManager.setIP(ip: nvrIPAddress )
                        nvrManager.setPort( port: nvrPortAddress )
                        
                        nvrManager.checkConnectionStatus(){data,error in
                            Log.shared().print(page: "ViewSetting", fn: "NVR Connection", type: "ERROR", text: "\(String(describing: error))")
                        }
                    }
                    //.buttonStyle(.bordered)
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                } header: {
                    Text("NVR Settings")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section {
                    HStack{
                        Text("Allowed")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text(notificationManager.hasPermission  ? "Enabled" : "Disabled")
                            .frame(alignment: .leading)
                        //.foregroundStyle(.tertiary)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    //Text("Allowed: \(notificationManager.hasPermission ? "Enabled" : "Disabled")" as String)
                    
                    if !notificationManager.hasPermission{
                        Button("Request Notification"){
                            Task{
                                await notificationManager.request()
                            }
                        }
                        //.buttonStyle(.bordered)
                        .buttonStyle(CustomPressEffectButtonStyle())
                        .tint(Color(white: 0.58))
                        .scaleEffect(scale)
                        .animation(.linear(duration: 1), value: scale)
                        .disabled(notificationManager.hasPermission)
                        .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                        .task {
                            await notificationManager.getAuthStatus()
                        }
                    }
                } header: {
                    Text("Notifications")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                 
                Section{
                    Button("Clear All Storage") {
                        showingAlert = true
                    }
                    .alert("Remove All Events", isPresented: $showingAlert) {
                        Button("OK", role: .destructive ) {
                            print("Clear All Storage")
                            //Delete SQLite
                            let _ = EventStorage.shared.delete()
                        }
                    }
                    //.buttonStyle(.bordered)
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                    
                    
                } header: {
                    Text("SQLite")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section{
                    ViewTipsSettingsPairDevie(title: "Pair Device", message: "Important. Anytime you update or restart the Viewu Server, you will need to repair your device")
                    
                    HStack{
                        Text("Paired:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text(viewuDevicePairedArg ? "Enabled" : "Disabled")
                            .frame(alignment: .leading)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                     
                    Button("Pair") {
                        viewuDevicePairedArg = false
                        for i in 0..<1 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                    withAnimation(.easeInOut) {
                                        mqttManager.publish(topic: "viewu/pairing", with: fcm)
                                    }
                                }
                            }
                    }
                    //.buttonStyle(.bordered)
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                } header: {
                    Text("Pair Device")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section{
                    Toggle("Enabled", isOn: $developerModeIsOn)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                        
                } header: {
                    Text("Developer Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section{
                    Button( action: {
                        isOnboarding = true
                        tipsSettingsPairDevice = true
                        tipsSettingsNVR = true
                        tipsNotificationTemplate = true
                        tipsNotificationDomain = true
                        tipsNotificationDefault = true
                        tipsLiveCameras = true
                    }) {
                        Text("Reset Tips")
                            .padding(0)
                            .frame(height: 20)
                    }
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                    
                } header: {
                    Text("Instructions and Tips")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section{
                        HStack{
                            Text("App:")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            Text(appVersion!)
                                .frame(alignment: .leading)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                        HStack{
                            Text("Build:")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            Text(appBuild!)
                                .frame(alignment: .leading)
                            //.foregroundStyle(.tertiary)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        HStack{
                            Text("Server:")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            Text(viewuServerVersion)
                                .frame(alignment: .leading)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        HStack{
                            Text("Frigate:")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            Text(frigateVersion)
                                .frame(alignment: .leading)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                } header: {
                    Text("Versions")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                 
                if developerModeIsOn {
                    Section{
                        ScrollView(.horizontal){
                            Text(fcm)
                                .frame(alignment: .leading)
                                .textSelection(.enabled)
                        }
                        
                    } header: {
                        Text("APN ID")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                
                Section {
                    Text("[Viewu](https://www.viewu.app)")
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    Text("[Support](https://github.com/mjehrhart/viewu)")
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    Text("[Reddit](https://www.reddit.com/r/viewu/)")
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    Text("[Installation Guide](https://installation.viewu.app)")
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                } header: {
                    Text("Information")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Text("Viewu™ 2024")
            }
            
            if( nts.alert ){
                PopupMiddle( onClose: {})
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
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
}

//#Preview {
//    ViewSettings(title: "Settings")
//}

