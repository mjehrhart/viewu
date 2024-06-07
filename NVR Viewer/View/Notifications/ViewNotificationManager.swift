//
//  ViewNotificationManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/5/24.
//

import SwiftUI

struct ViewAPN: View {
    
    let title: String
    
    let cNVR = APIRequester()
    let nvr = NVRConfig.shared()
    
    @StateObject var nts = NotificationTemplateString.shared()
    @StateObject var nvrManager = NVRConfig.shared()
    @StateObject var mqttManager = MQTTManager.shared()
    
    @AppStorage("apnTitle") private var apnTitle: String = ""
    @AppStorage("apnDomain") private var apnDomain: String = ""
    
    @State private var scale = 1.0
    let widthMultiplier:CGFloat = 2/5.8
    
    //tmp
    @State var templateList:[UUID] = []
    //@State var templateList2:[ViewNotificationManager] = []
    
    init(title: String) {
        self.title = title
        self.apnDomain = nvrManager.getUrl()
    }
    
    struct Popup: View {
        
        var body: some View {
             
            VStack{
                Spacer()
                Text("Saved")
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .topLeading)
            .background(.green.opacity(0.08))
            .ignoresSafeArea()
        }
    }
    
    var body: some View {
        
        if( nts.alert ){
            VStack{
            }
            .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .topLeading)
            .overlay(Popup())
        }
        
        VStack {
            Form {
                Section {
                    Text("Title:")
                        .frame(alignment: .leading)
                    
                    TextField("", text: $apnTitle)
                        .frame(alignment: .leading)
                    
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
                    Text("Docker Arguments")
                        .font(.caption)
                }
                
                Section {
                    Text("Domain:")
                        .frame(alignment: .leading)
                    
                    TextField("", text: $apnDomain)
                        .frame(alignment: .leading)
                    
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
                    Text("Docker Arguments")
                        .font(.caption)
                }
                
                Section {
                    List{
                        ForEach( 0..<nts.templates.count, id: \.self ){ index in
                            Text("\(nts.templates[index].template)")
                        }
                        .onDelete{ indexes in
                            print(indexes)
                            for index in indexes{
                                print(index)
                                nts.templates.remove(at: index)
                            }
                            
                            print(nts.templates)
                        }
                        
                        Button("Save Templates") {
                            
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
                }
                 
                ForEach( nts.templateList, id: \.self) { template in
                    template
                }
            }
        }
        .task {
            if(nts.templateList.isEmpty){
                nts.templateList.append(ViewNotificationManager(vid: UUID()))
            }
        }
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

//#Preview {
//    ViewNotificationManager(title: "Notification Manager")
//}
//                    Toggle(isOn: $templateSubLabel) {
//                        Text("Sub Label")
//                    }
//                    .toggleStyle(iOSCheckboxToggleStyle())
//                Section {
//                    LabeledContent("iOS Version", value: "16.2")
//                } header: {
//                    Text("About")
//                }
//                .listRowBackground(Color.yellow)
