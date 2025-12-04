//
//  ViewNotificationManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/5/24.
//

import SwiftUI
import TipKit
import PopupView


struct ViewAPN: View {
    
    let title: String
    var version = false
    
    var tipEventDomain = TipEventDomain()
    var tipEventNotifcationTemplate = TipEventNotifcationTemplate()
    var tipEventNotifcationManger = TipEventNotifcationManger()
    
    let cNVR = APIRequester()
    let nvr = NVRConfig.shared()
    
    @AppStorage("apnTitle") private var apnTitle: String = ""
    @AppStorage("apnDomain") private var apnDomain: String = ""
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
    
    @AppStorage("tipShowNotificationGeneral") private var tipShowNotificationGeneral: Bool = true
    @AppStorage("tipsNotificationTemplate") private var tipsNotificationTemplate: Bool = true
    @AppStorage("tipsNotificationDomain") private var tipsNotificationDomain: Bool = true
    @AppStorage("tipsNotificationDefault") private var tipsNotificationDefault: Bool = true
    
    @State private var scale = 1.0
    @State var templateList:[UUID] = []
    @State var showingPopup = true
    
    let widthMultiplier:CGFloat = 2/5.8
    
    @StateObject var nts = NotificationTemplateString.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var mqttManager = MQTTManager.shared()
    
    
    init(title: String) {
        
        self.title = title
        
        let x = viewuServerVersion.split(separator: ".")
        //let d1 = Int(x[0])
        let d2 = Int(x[1])
        let d3 = Int(x[2])
        
        if d2! <= 3 && d3! <= 0 {
            version = true
        }
        
        if apnDomain.isEmpty {
            apnDomain = nvrManager.getUrl()
        }
    }
    
    var body: some View {
        
        if version {
            VStack{
                Spacer()
                Text("This page requires Viewu Server 0.3.0 or later.")
                    .frame(alignment: .center)
                    .padding(.leading, 35)
                Text("You have \(viewuServerVersion) installed.")
                    .padding(.leading, 25)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .frame(width: UIScreen.screenWidth, height: 100, alignment: .topLeading)
            .background(.red.opacity(0.8))
        }
        
        if nts.notificationPaused {
            VStack{
                Text("Paused")
                    .frame(maxWidth: .infinity, maxHeight: 100, alignment: .center)
                    .fontWeight(.regular)
                    .font(.largeTitle)
                    .foregroundStyle(Color(red: 0.25, green: 0.25, blue: 0.25))
            }
            .frame(width: UIScreen.screenWidth, height: 100, alignment: .topLeading)
            .background(.red.opacity(0.75))
        }
        
        ZStack {
            
            GeometryReader { geomtry in
                Form {
                    Section {
                        
                        TextField("Message Title", text: $apnTitle)
                            .frame(alignment: .leading)
                            //.overlay(IndicatorOverlay(offset: -60, flag: nts.flagTitle))
                        //geomtry.size.width - 60
                            .overlay(IndicatorOverlay(offset: -80, flag: nts.flagTitle))
                            .onChange(of: apnTitle){
                                nts.flagTitle = false
                            }
                        Button("Save") {
                            for i in 0..<1 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                    withAnimation(.easeInOut) {
                                        let msg = "viewu_device_event::::title::::\(apnTitle)"
                                        mqttManager.publish(topic: "viewu/pairing", with: msg)
                                    }
                                }
                            }
                        }
                        //.buttonStyle(.bordered)
                        .buttonStyle(CustomPressEffectButtonStyle())
                        .scaleEffect(scale)
                        .animation(.linear(duration: 1), value: scale)
                        //.frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                        .frame(width: geomtry.size.width - 50, alignment: .trailing)
                        
                    } header: {
                        HStack{
                            
                            if !tipsNotificationDefault{
                                Text("Notification Title")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            ViewTipsNotificationManager(title: "Notification Manager", message: "Important. Anytime you update or restart the Viewu Server, you will need to repair your device and resynce these values." )
                        }
                    }
                    
                    Section {
                        
                        TextField("https://domaintoviewnvr.com", text: $apnDomain)
                            .frame(alignment: .leading)
                            .autocorrectionDisabled()
                            .overlay(IndicatorOverlay(offset: (geomtry.size.width - 340), flag: nts.flagDomain))
                            .onChange(of: apnDomain){
                                nts.flagDomain = false
                            }
                        
                        Button("Save") {
                            for i in 0..<1 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                    withAnimation(.easeInOut) {
                                        let msg = "viewu_device_event::::domain::::\(apnDomain)"
                                        mqttManager.publish(topic: "viewu/pairing", with: msg)
                                    }
                                }
                            }
                        }
                        //.buttonStyle(.bordered)
                        .buttonStyle(CustomPressEffectButtonStyle())
                        .scaleEffect(scale)
                        .animation(.linear(duration: 1), value: scale)
                        //.frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                        .frame(width: geomtry.size.width - 50, alignment: .trailing)
                        
                    } header: {
                        HStack{
                            if !tipsNotificationDomain{
                                Text("Accessible Domain")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            ViewTipsNotificationDomain(title: "Accessible Domain", message: "For secure access to clips and snapshots, Viewu should be configured with a public domain name using an https:// endpoint. To enhance security and ensure only authorized users can reach the service, it is best practice to place this domain behind a VPN solution such as Tailscale. If a secure public endpoint is not available, you may use http:// for local-network access only, including viewing notification images on your LAN." )
                        }
                    }
                    
                    Section {
                        //TipView(tipEventNotifcationTemplate, arrowEdge: .bottom)
                        
                        List{
                            Text("")
                                .frame(maxWidth: .infinity, maxHeight: 4, alignment: .leading)
                                .overlay(IndicatorOverlay(offset: -65, flag: nts.flagTemplate))
                            
                            ForEach( 0..<nts.templates.count, id: \.self ){ index in
                                Text("\(nts.templates[index].template)")
                            }
                            .onDelete{ indexes in
                                //print(indexes)
                                for index in indexes{
                                    //print(index)
                                    nts.templates.remove(at: index)
                                }
                                
                                nts.flagTemplate = false
                            }
                            
                            Button("Save") {
                                
                                let templateString = nts.buildTemplateString()
                                
                                for i in 0..<1 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                        withAnimation(.easeInOut) {
                                            let msg = "viewu_device_event::::template::::\(templateString)"
                                            mqttManager.publish(topic: "viewu/pairing", with: msg)
                                        }
                                    }
                                }
                            }
                            //.buttonStyle(.bordered)
                            .buttonStyle(CustomPressEffectButtonStyle())
                            .scaleEffect(scale)
                            .animation(.linear(duration: 1), value: scale)
                            //.frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                            .frame(width: geomtry.size.width - 50, alignment: .trailing)
                            
                        }
                    } header: {
                        HStack{
                            if !tipsNotificationTemplate {
                                Text("Saved Templates")
                                    .foregroundColor(.orange)
                            }
                            ViewTipsNotificationTemplate(title: "Notification Templates", message: "This helps reduce the number of notifications received and allows you to specify which events you get notifications for. Filtering notifications based on the type field can significantly reduce noise and ensure users receive only the most relevant updates" )
                        }
                    }
                    
                    ForEach( nts.templateList, id: \.self) { template in
                        template
                    }
                    
                    Section{
                        Toggle("Pause", isOn: nts.$notificationPaused)
                            .onChange(of: nts.notificationPaused){
                                for i in 0..<1 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                        withAnimation(.easeInOut) {
                                            //print("isPaused :: \(nts.notificationPaused)")
                                            let msg = "viewu_device_event::::paused::::\(nts.notificationPaused)"
                                            mqttManager.publish(topic: "viewu/pairing", with: msg)
                                            //nts.notificationPaused.toggle()
                                        }
                                    }
                                }
                            }
                            .tint(Color(red: 0.153, green: 0.69, blue: 1))
                    } header: {
                        
                        Text("Notifications")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if( nts.alert ){
                    PopupMiddle( onClose: {})
                }
            }
        }
        .task {
            if(nts.templateList.isEmpty){
                nts.templateList.append(ViewNotificationManager(vid: UUID()))
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .onAppear {
            
        }
    }
    
    
    struct IndicatorOverlay: View {
        
        var offset: CGFloat
        var flag: Bool
        var body: some View {
            Image(systemName: "circle.fill")
                //.frame(width: UIScreen.screenWidth + offset, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle( flag ? .green : .red)
                .font(.system(size: 8))
        }
    }
    
    struct Popup: View {
        
        var body: some View {
            
            VStack{
                Spacer()
                
                VStack{
                    
                    HStack{
                        Spacer()
                            .frame(width: 100, alignment: .center)
                        
                        Text("Synced with Viewu Server")
                            .multilineTextAlignment(.center)
                            .font(.title)
                            .foregroundColor(.secondary)
                            .frame(width: 300, alignment: .center)
                        Spacer()
                    }
                    .background(.mint.opacity(0.5))
                    
                }
                .frame(width: 300, height: 250, alignment: .center)
                
                Spacer()
                
            }
            .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .topLeading)
            .background(.white)
            .ignoresSafeArea()
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
}

struct PopupMiddle: View {
    
    var onClose: () -> Void
    
    var body: some View {
        
        VStack{
            Spacer()
            
            VStack{
                
                HStack{
                    VStack(spacing: 20) {
                        
                        Text("Synced with Viewu Server")
                            .foregroundColor(.black)
                            .font(.system(size: 19))
                            .padding(.bottom, 12)
                        
                        Image(systemName: "server.rack")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 226, maxHeight: 100)
                        
                    }
                    .padding(EdgeInsets(top: 37, leading: 24, bottom: 40, trailing: 24))
                    .background(Color.white.cornerRadius(20))
                    .padding(.horizontal, 10)
                }
                .padding(.trailing, 40 )
                .padding(.leading, 70 )
            }
            
            Spacer()
            
        }
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .topLeading)
        .background(.gray).opacity(0.9)
        .ignoresSafeArea()
    }
}

struct ViewNotificationManager: View, Hashable, Equatable {
    
    let cNVR = APIRequester()
    let nvr = NVRConfig.shared()
    
    @StateObject var nts = NotificationTemplateString.shared()
    @ObservedObject  var nt = NotificationTemplate()
    //@ObservedObject var config = NVRConfigurationSuper.shared()
    @ObservedObject var config = NVRConfigurationSuper2.shared()
    
    @State var cameraTemplate = ""
    @State var labelTemplate = ""
    @State var currentZoneTemplate = ""
    @State var enteredZoneTemplate = ""
    @State var typeTemplate = ""
    @State var templateString = ""
    
    @State private var scale = 1.0
    
    @State var id = UUID();
    @State var vid = UUID();
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: ViewNotificationManager, rhs: ViewNotificationManager) -> Bool {
        return lhs.vid == rhs.vid && lhs.id == rhs.id && lhs.cameraTemplate == rhs.cameraTemplate &&
        lhs.labelTemplate == rhs.labelTemplate && lhs.currentZoneTemplate == rhs.currentZoneTemplate &&
        lhs.enteredZoneTemplate == rhs.enteredZoneTemplate && lhs.typeTemplate == rhs.typeTemplate &&
        lhs.templateString == rhs.templateString
    }
    
    func buildTemplate() -> String {
        
        templateString = ""
        
        if !cameraTemplate.isEmpty {
            
            if cameraTemplate.hasSuffix("|") {
                
                let startIndex = cameraTemplate.index(cameraTemplate.startIndex, offsetBy: 0)
                let endIndex = cameraTemplate.index(cameraTemplate.endIndex, offsetBy: -1)
                let range = startIndex..<endIndex
                let substring = cameraTemplate[range]
                cameraTemplate = String(substring)
            }
            
            templateString += "\(cameraTemplate), "
        }
        if !labelTemplate.isEmpty {
            
            if labelTemplate.hasSuffix("|") {
                
                let startIndex = labelTemplate.index(labelTemplate.startIndex, offsetBy: 0)
                let endIndex = labelTemplate.index(labelTemplate.endIndex, offsetBy: -1)
                let range = startIndex..<endIndex
                let substring = labelTemplate[range]
                labelTemplate = String(substring)
            }
            
            templateString += "\(labelTemplate), "
        }
        if !currentZoneTemplate.isEmpty {
            
            if currentZoneTemplate.hasSuffix("|") {
                
                let startIndex = currentZoneTemplate.index(currentZoneTemplate.startIndex, offsetBy: 0)
                let endIndex = currentZoneTemplate.index(currentZoneTemplate.endIndex, offsetBy: -1)
                let range = startIndex..<endIndex
                let substring = currentZoneTemplate[range]
                currentZoneTemplate = String(substring)
            }
            
            templateString += "\(currentZoneTemplate), "
        }
        if !enteredZoneTemplate.isEmpty {
            
            if enteredZoneTemplate.hasSuffix("|") {
                
                let startIndex = enteredZoneTemplate.index(enteredZoneTemplate.startIndex, offsetBy: 0)
                let endIndex = enteredZoneTemplate.index(enteredZoneTemplate.endIndex, offsetBy: -1)
                let range = startIndex..<endIndex
                let substring = enteredZoneTemplate[range]
                enteredZoneTemplate = String(substring)
            }
            
            templateString += "\(enteredZoneTemplate), "
        }
        if !typeTemplate.isEmpty {
            
            if typeTemplate.hasSuffix("|") {
                
                let startIndex = typeTemplate.index(typeTemplate.startIndex, offsetBy: 0)
                let endIndex = typeTemplate.index(typeTemplate.endIndex, offsetBy: -1)
                let range = startIndex..<endIndex
                let substring = typeTemplate[range]
                typeTemplate = String(substring)
            }
            
            templateString += "\(typeTemplate), "
        }
        
        if templateString.hasSuffix(", ") {
            
            let startIndex = templateString.index(templateString.startIndex, offsetBy: 0)
            let endIndex = templateString.index(templateString.endIndex, offsetBy: -2)
            let range = startIndex..<endIndex
            let substring = templateString[range]
            //print(substring)
            templateString = String(substring)
        }
        
        nts.pushTemplate(id: id, template: templateString)
        
        return templateString
    }
    
    var body: some View {
        
        Section {
            
            DisclosureGroup {
                ForEach( 0..<nt.cameras.count, id: \.self ){ index in
                    
                    Toggle(nt.cameras[index].name, isOn: $nt.cameras[index].state)
                        .onChange(of: nt.cameras[index].state) {
                            
                            var tmp = ""
                            cameraTemplate = ""
                            for camera in nt.cameras {
                                if camera.state {
                                    tmp += camera.name + "|"
                                }
                            }
                            if !tmp.isEmpty {
                                cameraTemplate = "camera==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Camera")
                    .frame(height: 40)
            }
            
            DisclosureGroup {
                ForEach( 0..<$nt.labels.count, id: \.self){ index in
                    
                    Toggle(nt.labels[index].name, isOn: $nt.labels[index].state)
                        .onChange(of: nt.labels[index].state) {
                            var tmp = ""
                            labelTemplate = ""
                            for label in nt.labels {
                                if label.state {
                                    tmp += label.name + "|"
                                }
                            }
                            if !tmp.isEmpty {
                                labelTemplate = "label==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Label")
                    .frame(height: 40)
            }
            
            DisclosureGroup {
                ForEach( 0..<$nt.enteredZones.count, id: \.self){ index in
                    Toggle(nt.enteredZones[index].name, isOn: $nt.enteredZones[index].state)
                        .onChange(of: nt.enteredZones[index].state) {
                            var tmp = ""
                            enteredZoneTemplate = ""
                            for zone in nt.enteredZones {
                                if zone.state {
                                    tmp += zone.name + "|"
                                }
                            }
                            if !tmp.isEmpty {
                                enteredZoneTemplate = "entered_zones==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Entered Zone")
                    .frame(height: 40)
            }
            
            DisclosureGroup {
                ForEach( 0..<$nt.currentZones.count, id: \.self){ index in
                    Toggle(nt.currentZones[index].name, isOn: $nt.currentZones[index].state)
                        .onChange(of: nt.currentZones[index].state) {
                            var tmp = ""
                            currentZoneTemplate = ""
                            for zone in nt.currentZones {
                                if zone.state {
                                    tmp += zone.name + "|"
                                }
                            }
                            if !tmp.isEmpty {
                                currentZoneTemplate = "current_zones==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Current Zone")
                    .frame(height: 40)
            }
            
            DisclosureGroup {
                ForEach( 0..<$nt.types.count, id: \.self){ index in
                    Toggle(nt.types[index].name, isOn: $nt.types[index].state)
                        .onChange(of: nt.types[index].state) {
                            var tmp = ""
                            typeTemplate = ""
                            for camera in nt.types {
                                if camera.state {
                                    tmp += camera.name + "|"
                                }
                            }
                            if !tmp.isEmpty {
                                typeTemplate = "type==\(tmp)"
                            }
                            nt.templateString = buildTemplate()
                        }
                }
            } label: {
                Text("Type")
                    .frame(height: 40)
            }
            
            
            ScrollView(.horizontal){
                Text(templateString)
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: 50)
            }
            
            GeometryReader { geometry in
                Button("Add Template", systemImage: "plus.app") {
                    nts.templateList.removeAll()
                    nts.templateList.append(ViewNotificationManager(vid: UUID()))
                }
                //.buttonStyle(.bordered)
                .buttonStyle(CustomPressEffectButtonStyle())
                .scaleEffect(scale)
                .animation(.linear(duration: 1), value: scale)
                //.frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                .frame(width: geometry.size.width+5, alignment: .trailing)
            }
            
        } header: {
            Text("Template")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .task {
            nt.setCameras(items: config.item.cameras)
            nt.setLabels(items: config.item.cameras)
            nt.setZones(items: config.item.cameras)
            nt.setTypes()
        }
    }
    
    struct iOSCheckboxToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            // 1
            Button(action: {
                
                // 2
                configuration.isOn.toggle()
                
            }, label: {
                HStack {
                    // 3
                    Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    
                    configuration.label
                }
            })
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
}

struct TipEventNotifcationManger: Tip {
    
    @Parameter
    static var shownBefore: Bool = false
    
    var title: Text {
        Text("Notification Manager")
    }
    
    var message: Text? {
        Text("Important. Anytime you update or restart the Viewu Server, you will need to resync these values.")
    }
    
    var image: Image? {
        Image(systemName: "info.bubble")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$shownBefore) { $0 == false }
        ]
    }
    
    var options: [TipOption] = [MaxDisplayCount(1)]
    
}

struct TipEventNotifcationTemplate: Tip {
    
    @Parameter
    static var shownBefore: Bool = false
    
    var title: Text {
        Text("Notification Templates")
    }
    
    var message: Text? {
        Text("This helps reduce the number of notifications received and allows you to specify which events you get notifications for. Filtering notifications based on the type field can significantly reduce noise and ensure users receive only the most relevant updates.")
    }
    
    var image: Image? {
        Image(systemName: "info.bubble")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$shownBefore) { $0 == false }
        ]
    }
    
    var options: [TipOption] = [MaxDisplayCount(1)]
    
}

struct TipEventDomain: Tip {
    
    @Parameter
    static var shownBefore: Bool = false
    
    var title: Text {
        Text("Accessible Domain")
    }
    
    var message: Text? {
        Text("For accessing the NVRs clips and snapshots, it's recommended to use a public domain name for Viewu. Your domain must start with http:// or https://. To enhance security, it's best practice to protect this domain with a VPN like Tailscale, ensuring that only authorized individuals can access it.")
    }
    
    var image: Image? {
        Image(systemName: "info.bubble")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$shownBefore) { $0 == false }
        ]
    }
    
    var options: [TipOption] = [MaxDisplayCount(1)]
    
}
