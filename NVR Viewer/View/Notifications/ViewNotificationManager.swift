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
    
    @StateObject var nts = NotificationTemplateString.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var mqttManager = MQTTManager.shared()
    
    @AppStorage("apnTitle") private var apnTitle: String = ""
    @AppStorage("apnDomain") private var apnDomain: String = ""
    
    @State private var scale = 1.0
    let widthMultiplier:CGFloat = 2/5.8
     
    @State var templateList:[UUID] = []
    @State var showingPopup = true
    
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
     
    init(title: String) {
        self.title = title
        
        print(viewuServerVersion)
        let x = viewuServerVersion.split(separator: ".")
        let d1 = Int(x[0])
        let d2 = Int(x[1])
        let d3 = Int(x[2])
         
        if d2! <= 2 && d3! <= 5 {
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
                Text("This page requires Viewu Server 0.2.6 or later.")
                    //.multilineTextAlignment(.center)
                    .frame(alignment: .center)
                    .padding(.leading, 35)
                Text("You have \(viewuServerVersion) installed.")
                    //.multilineTextAlignment(.center)
                    .padding(.leading, 25)
                    .frame(width: .infinity, alignment: .center)
                Spacer()
            }
            .frame(width: UIScreen.screenWidth, height: 100, alignment: .topLeading)
            .background(.red.opacity(0.8))
        }
 
            ZStack {
                
                Form {
                      
                    TipView(tipEventNotifcationManger, arrowEdge: .bottom)
                    
                    Section{
                        Toggle("Pause", isOn: nts.$notificationPaused)
                            .onChange(of: nts.notificationPaused){
                                for i in 0..<1 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                        withAnimation(.easeInOut) {
                                            print("isPaused :: \(nts.notificationPaused)")
                                            let msg = "viewu_device_event::::paused::::\(nts.notificationPaused)"
                                            mqttManager.publish(topic: "viewu/pairing", with: msg)
                                            //nts.notificationPaused.toggle()
                                        }
                                    }
                                }
                            }
                    } header: {
                        Text("Notifications")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Section {
                        
                        TextField("Message Title", text: $apnTitle)
                            .frame(alignment: .leading)
                            .overlay(IndicatorOverlay(offset: -60, flag: nts.flagTitle))
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
                        .buttonStyle(.bordered)
                        .scaleEffect(scale)
                        .animation(.linear(duration: 1), value: scale)
                        .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                        
                    } header: {
                        Text("Notification Title")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    //.headerProminence(.increased)
                    //.foregroundColor(.white)
                    //.listRowBackground(Color.mint)
                     
                    Section {
                        TipView(tipEventDomain, arrowEdge: .bottom)
                        
                        TextField("https://domaintoviewnvr.com", text: $apnDomain)
                            .frame(alignment: .leading)
                            .autocorrectionDisabled()
                            .overlay(IndicatorOverlay(offset: -60, flag: nts.flagDomain))
                            .onChange(of: apnDomain){
                                nts.flagDomain = false
                            }
                            //.popoverTip(tipEventDomain)
                        
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
                        .buttonStyle(.bordered)
                        .scaleEffect(scale)
                        .animation(.linear(duration: 1), value: scale)
                        .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                        
                    } header: {
                        Text("Accessible Domain")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Section {
                        TipView(tipEventNotifcationTemplate, arrowEdge: .bottom)
                        List{
                            Text("")
                                .frame(width: .infinity, height: 4, alignment: .leading)
                                .overlay(IndicatorOverlay(offset: 265, flag: nts.flagTemplate))
                            
                            ForEach( 0..<nts.templates.count, id: \.self ){ index in
                                Text("\(nts.templates[index].template)")
                            }
                            .onDelete{ indexes in
                                print(indexes)
                                for index in indexes{
                                    print(index)
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
                            .buttonStyle(.bordered)
                            .scaleEffect(scale)
                            .animation(.linear(duration: 1), value: scale)
                            .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
                            
                        }
                    } header: {
                        Text("Saved Templates")
                            .foregroundColor(.orange)
                    }
                    
                    ForEach( nts.templateList, id: \.self) { template in
                        template
                    }
                }
                
                if( nts.alert ){
                    PopupMiddle( onClose: {})
                }
            }
            .task {
                if(nts.templateList.isEmpty){
                    nts.templateList.append(ViewNotificationManager(vid: UUID()))
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
    }
    
    struct IndicatorOverlay: View {
         
        var offset: CGFloat
        var flag: Bool
        var body: some View {
            Image(systemName: "circle.fill")
                .frame(width: UIScreen.screenWidth + offset, alignment: .trailing)
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
                            //.frame(maxWidth: .infinity, alignment: .center)
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
    @ObservedObject var config = NVRConfigurationSuper.shared()
    
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
                    .frame(width: .infinity, height: 50)
            }
            
            Button {
                nts.templateList.removeAll()
                nts.templateList.append(ViewNotificationManager(vid: UUID()))
            } label: {
                Text("Add Template")
                Image(systemName: "plus.app")
            }
            .buttonStyle(.bordered)
            .scaleEffect(scale)
            .animation(.linear(duration: 1), value: scale)
            .frame(width: UIScreen.screenWidth-50, alignment: .trailing)
            
            
            
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
