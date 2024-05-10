//
//  ViewSettings.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI


struct ViewSettings: View {
    
    let title: String
    //let notify = NotificationHandler()
    @StateObject var notificationManager = NotificationManager()
    
    var currentAppState = MQTTAppState()
    
    @StateObject var mqttManager = MQTTManager.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    
    @State private var scale = 1.0
    @State private var showingAlert = false
    
    @AppStorage("nvrIPAddress") private var nvrIPAddress: String = ""
    @AppStorage("nvrPortAddress") private var nvrPortAddress: String = ""
    @AppStorage("nvrIsHttps") private var nvrIsHttps: Bool = false
    @AppStorage("developerModeIsOn") private var developerModeIsOn: Bool = false
    
    @AppStorage("mqttIPAddress") private var mqttIPAddress: String = ""
    @AppStorage("mqttPortAddress") private var mqttPortAddress: String = ""
    @AppStorage("mqttIsAnonUser") private var mqttIsAnonUser: Bool = true
    @AppStorage("mqttUser") private var mqttUser: String = ""
    @AppStorage("mqttPassword") private var mqttPassword: String = ""
     
    var fcm: String = UserDefaults.standard.string(forKey: "fcm") ?? "0"
    //var viewuPairedDevice: Bool = UserDefaults.standard.bool(forKey: "viewu_device_paired")
    @State @AppStorage("viewu_device_paired") private var viewuDevicePairedArg: Bool = false
    
    let widthMultiplier:CGFloat = 2/5.8
    var body: some View {
        VStack {
            
            Form {
                
                Section{
                    Toggle("Enabled", isOn: $developerModeIsOn)
                } header: {
                    Text("Developer Mode")
                        .font(.caption)
                }
                
                if developerModeIsOn {}
                Section {
                    HStack{
                        Text("Broker Address:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        TextField("0.0.0.0", text: $mqttIPAddress)
                            .frame(alignment: .leading)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)

                    HStack{
                        Text("Port:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        TextField("1883", text: $mqttPortAddress)
                            .frame(alignment: .leading)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)

                    HStack{
                        Text("Topic:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("viewu/pairing")
                            .frame(alignment: .leading)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    if developerModeIsOn {
                        HStack{
                            Text("")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            Text("frigagte/events")
                                .frame(alignment: .leading)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        
                    }
                    
                    Toggle("Anonymous", isOn: $mqttIsAnonUser)
                        .onTapGesture{
                            if !mqttIsAnonUser {
                                mqttUser = ""
                                mqttPassword = ""
                            }
                        }
                    if !mqttIsAnonUser {
                        VStack{
                            HStack{
                                Text("User:")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                TextField("", text: $mqttUser)
                                    .frame(alignment: .leading)
                                    .foregroundStyle(.tertiary)
                                    .disabled(mqttIsAnonUser)
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                            HStack{
                                Text("Password:")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                TextField("", text: $mqttPassword)
                                    .frame(alignment: .leading)
                                    .foregroundStyle(.tertiary)
                                    .disabled(mqttIsAnonUser)
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading) 
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    }
                    
                    Label(mqttManager.isConnected() ? "Connected" : "Disconnected", systemImage: "cable.connector")
                        .frame(width: UIScreen.screenWidth - 70, alignment: .trailing)
                        .foregroundStyle(mqttManager.isConnected() ? .green : .red)
                    
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
                    .buttonStyle(.bordered)
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                     
                } header: {
                    Text("MQTT Settings")
                        .font(.caption)
                }
                   
                Section {
                    HStack{
                        Text("Address:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            TextField("0.0.0.0", text: $nvrIPAddress)
                                .frame(alignment: .leading) 
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    HStack{
                        Text("Port:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        TextField("5000", text: $nvrPortAddress)
                            .frame(alignment: .leading)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    Toggle("Https", isOn: $nvrIsHttps)
//                    LabeledContent("NVR Synced", value: "No")
                    
                    //TODO this doesnt refresh as expected
                    Label(nvrManager.getConnectionState() ? "Connected" : "Disconnected", systemImage: "cable.connector")
                        .frame(width: UIScreen.screenWidth - 70, alignment: .trailing)
                        .foregroundStyle(nvrManager.getConnectionState() ? .green : .red)
                    
                    Button("Save Connection") {
                        //Sync data accross view and model
                        nvrManager.setHttps(http: nvrIsHttps )
                        nvrManager.setIP(ip: nvrIPAddress )
                        nvrManager.setPort( port: nvrPortAddress )
                        
                        nvrManager.checkConnectionStatus(){data,error in
                            //do nothing here
                        }
                    }
                    .buttonStyle(.bordered)
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                    
                } header: {
                    Text("NVR Settings")
                        .font(.caption)
                }
                
                Section {
                    HStack{
                        Text("Allowed")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text(notificationManager.hasPermission  ? "Enabled" : "Disabled")
                            .frame(alignment: .leading)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    //Text("Allowed: \(notificationManager.hasPermission ? "Enabled" : "Disabled")" as String)
                    
                    if !notificationManager.hasPermission{
                        Button("Request Notification"){
                            Task{
                                await notificationManager.request()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(notificationManager.hasPermission)
                        .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                        .task {
                            await notificationManager.getAuthStatus()
                        }
                    }
                } header: {
                    Text("Notifications")
                        .font(.caption)
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
                    .buttonStyle(.bordered)
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                    
                    
                } header: {
                    Text("SQLite")
                        .font(.caption)
                }
                
                Section{
                    HStack{
                        Text("Paired:")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text(viewuDevicePairedArg ? "Enabled" : "Disabled")
                            .frame(alignment: .leading)
                            .foregroundStyle(.tertiary)
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
                    .buttonStyle(.bordered)
                    .scaleEffect(scale)
                    .animation(.linear(duration: 1), value: scale)
                    .frame(width: UIScreen.screenWidth - 50, alignment: .trailing)
                } header: {
                    Text("Pair Device")
                        .font(.caption)
                }
                
                if developerModeIsOn {
                    Section{
                        ScrollView(.horizontal){
                            Text(fcm)
                                .frame(alignment: .leading)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                        
                    } header: {
                        Text("APN ID")
                            .font(.caption)
                    }
                }
            }
            Spacer()
        }
        .onAppear{
            //            print("ContentView::onAppear")
            //            //check accesibilty to nvr
            //            nvrManager.checkConnectionStatus()
            //
            //            //connect to mqtt broker
            //            mqttManager.initializeMQTT()
            //            mqttManager.connect()
        }
        .navigationBarTitle(title, displayMode: .inline)
//        .scrollContentBackground(.hidden)
//        .toolbarBackground(.secondary, for: .navigationBar)
//        .toolbarBackground(.visible, for: .navigationBar)
    }
    
}

#Preview {
    ViewSettings(title: "Settings")
}

