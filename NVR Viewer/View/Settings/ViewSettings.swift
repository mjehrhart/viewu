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
    
    let nvr = NVRConfig.shared()
    let api = APIRequester()
    
    @AppStorage("developerModeIsOn") private var developerModeIsOn: Bool = false
    @AppStorage("showLogView") private var showLogView: Bool = false
    @AppStorage("showNVRView") private var showNVRView: Bool = false
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
    
    var fcm: String = UserDefaults.standard.string(forKey: "fcm") ?? "0"
    
    @AppStorage("viewu_device_paired") private var viewuDevicePairedArg: Bool = false
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
    @AppStorage("frigateVersion") private var frigateVersion: String = "0.0-0"
    
    @AppStorage("log_level") private var logLevelRaw: String = LogLevel.debug.rawValue

    @StateObject var nts = NotificationTemplateString.shared()
    
    let widthMultiplier:CGFloat = 2/5.8   // kept; no longer used for fixed widths
    let fieldWidth = UIScreen.main.bounds.width * 0.5
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    @Environment(\.dismiss) var dismiss
     
    var body: some View {
        
        ZStack {
            Form {
                // MARK: Frigate+
                Section {
                    Toggle("Enabled", isOn: $frigatePlusOn)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                } header: {
                    Text("Frigate+")
                        .foregroundColor(.orange)
                }
                
                // MARK: Notification Manager on/off
                Section {
                    Toggle("Enabled", isOn: $notificationModeIsOn)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                } header: {
                    Text("Notification Manager")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // MARK: Camera Stream
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
                    
                    Toggle("HLS", isOn: $cameraHLS)
                        .onChange(of: cameraHLS) {
                            if cameraHLS == true {
                                camerGo2Rtc = false
                                cameraRTSPPath = false
                                cameraSubStream = false
                            } else {
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
                
                // MARK: NVR Settings (Auth Types)
                Section {
                    ViewAuthTypes()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                } header: {
                    HStack {
                        if !tipsSettingsNVR {
                            Text("NVR Settings")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        ViewTipsSettingsNVR(
                            title: "Connection Requirements",
                            message: "For optimal security, Viewu requires a secured HTTPS connection. HTTP is supported only for devices on your local network. To ensure encrypted communication and protect your video data, configure your server to use HTTPS whenever accessible outside your LAN."
                        )
                        .frame(maxHeight: .infinity)
                    }
                }
                
                // MARK: MQTT Settings
                Section {
                    
                    HStack {
                        Text("Broker Address")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        TextField("0.0.0.0", text: $mqttIPAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Port")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        TextField("1883", text: $mqttPortAddress)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    LabeledContent {
                        Text("viewu/pairing")
                    } label: {
                        Text("Topic")
                    }
                    
                    if developerModeIsOn {
                        LabeledContent {
                            Text("frigate/events")
                        } label: {
                            Text("") // spacer label
                        }
                    }
                    
                    Toggle("Anonymous", isOn: $mqttIsAnonUser)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    
                    if !mqttIsAnonUser {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            HStack(spacing: 8) {
                                Text("User")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                 
                                        TextField("", text: $mqttUser)
                                            .disabled(mqttIsAnonUser)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                 
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                           
                            Divider()
                            
                            HStack(spacing: 8) {
                                Text("Password")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                 
                                HStack {
                                   ZStack {
                                       if !showPassword {
                                           SecureField("", text: $mqttPassword)
                                               .autocapitalization(.none)
                                               .autocorrectionDisabled()
                                               .disabled(mqttIsAnonUser)
                                       } else {
                                           TextField("", text: $mqttPassword)
                                               .autocapitalization(.none)
                                               .autocorrectionDisabled()
                                               .disabled(mqttIsAnonUser)
                                       }
                                   }

                                   Button("", systemImage: showPassword ? "eye.slash" : "eye") {
                                       showPassword.toggle()
                                   }
                                   .buttonStyle(.borderless)   // or .plain
                                   .foregroundStyle(Color(red: 0.153, green: 0.69, blue: 1))
                               }
                               .frame(maxWidth: .infinity, alignment: .trailing)
                                 
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                        }
                    }
                    
                    Label(mqttManager.isConnected() ? "Connected" : "Disconnected",
                          systemImage: "cable.connector")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(
                            mqttManager.isConnected()
                            ? Color(red: 0.153, green: 0.69, blue: 1)
                            : .red
                        )
                    
                    Button("Save Connection") {
                        mqttManager.currentAppState.setAppConnectionState(state: .disconnected)
                        
                        mqttManager.setAnonymous(anonymous: mqttIsAnonUser )
                        mqttManager.setIP(ip: mqttIPAddress )
                        mqttManager.setPort( port: mqttPortAddress )
                        mqttManager.setCredentials(user: mqttUser, password: mqttPassword)
                        
                        mqttManager.initializeMQTT()
                        mqttManager.connect()
                    }
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                } header: {
                    Text("MQTT Settings")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // MARK: Notifications permission
                Section {
                    LabeledContent {
                        Text(notificationManager.hasPermission ? "Enabled" : "Disabled")
                    } label: {
                        Text("Allowed")
                    }
                    
                    if !notificationManager.hasPermission {
                        Button("Request Notification") {
                            Task {
                                await notificationManager.request()
                            }
                        }
                        .buttonStyle(CustomPressEffectButtonStyle())
                        .tint(Color(white: 0.58))
                        .scaleEffect(scale)
                        .animation(.linear(duration: 1), value: scale)
                        .disabled(notificationManager.hasPermission)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .task {
                            await notificationManager.getAuthStatus()
                        }
                    }
                } header: {
                    Text("Notifications")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // MARK: SQLite
                Section {
                    Button("Clear All Storage") {
                        showingAlert = true
                    }
                    .alert("Remove All Events", isPresented: $showingAlert) {
                        Button("OK", role: .destructive ) {
                            _ = EventStorage.shared.delete()
                        }
                    }
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                } header: {
                    Text("SQLite")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // MARK: Pair Device
                Section {
                    LabeledContent {
                        Text(viewuDevicePairedArg ? "Enabled" : "Disabled")
                    } label: {
                        Text("Paired:")
                    }
                    
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
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                } header: {
                    HStack {
                        if !tipsSettingsPairDevice {
                            Text("Pair Device")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        ViewTipsSettingsPairDevie(
                            title: "Pair Device",
                            message: "Important. Anytime you update or restart the Viewu Server, you will need to repair your device."
                        )
                    }
                }
                
                // MARK: Developer Mode
                Section {

                    Toggle("Show Log", isOn: $showLogView)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))

                    Toggle("Show View", isOn: $showNVRView)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))

                    Toggle("Display URLs", isOn: $developerModeIsOn)
                        .tint(Color(red: 0.153, green: 0.69, blue: 1))

                    // MARK: Log Level (three mutually exclusive toggles)

                    Toggle("Debug – all logs", isOn: Binding(
                        get: {
                            (LogLevel(rawValue: logLevelRaw) ?? .debug) == .debug
                        },
                        set: { isOn in
                            if isOn {
                                logLevelRaw = LogLevel.debug.rawValue
                            }
                        }
                    ))
                    .tint(Color(red: 0.153, green: 0.69, blue: 1))

                    Toggle("Warning – warnings & errors", isOn: Binding(
                        get: {
                            (LogLevel(rawValue: logLevelRaw) ?? .debug) == .warning
                        },
                        set: { isOn in
                            if isOn {
                                logLevelRaw = LogLevel.warning.rawValue
                            }
                        }
                    ))
                    .tint(Color(red: 1.0, green: 0.6, blue: 0.0))   // orange-ish

                    Toggle("Error – errors only", isOn: Binding(
                        get: {
                            (LogLevel(rawValue: logLevelRaw) ?? .debug) == .error
                        },
                        set: { isOn in
                            if isOn {
                                logLevelRaw = LogLevel.error.rawValue
                            }
                        }
                    ))
                    .tint(.red)

                } header: {
                    Text("Developer Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                }


                
                // MARK: Instructions and Tips
                Section {
                    Button {
                        isOnboarding = true
                        tipsSettingsPairDevice = true
                        tipsSettingsNVR = true
                        tipsNotificationTemplate = true
                        tipsNotificationDomain = true
                        tipsNotificationDefault = true
                        tipsLiveCameras = true
                    } label: {
                        Text("Reset Tips")
                            .frame(height: 20)
                    }
                    .buttonStyle(CustomPressEffectButtonStyle())
                    .tint(Color(white: 0.58))
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                } header: {
                    Text("Instructions and Tips")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // MARK: Versions
                Section {
                    if let appVersion {
                        LabeledContent {
                            Text(appVersion)
                        } label: {
                            Text("App:")
                        }
                    }
                    
                    if let appBuild {
                        LabeledContent {
                            Text(appBuild)
                        } label: {
                            Text("Build:")
                        }
                    }
                    
                    LabeledContent {
                        Text(viewuServerVersion)
                    } label: {
                        Text("Server:")
                    }
                    
                    LabeledContent {
                        Text(frigateVersion)
                    } label: {
                        Text("Frigate:")
                    }
                    
                } header: {
                    Text("Versions")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // MARK: APN ID (dev only)
                if developerModeIsOn {
                    Section {
                        ScrollView(.horizontal) {
                            Text(fcm)
                                .textSelection(.enabled)
                        }
                    } header: {
                        Text("APN ID")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // MARK: Information links
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
            
            if nts.alert {
                PopupMiddle(onClose: {})
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
    }
}
