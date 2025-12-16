//
//  NotificationTemplate.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/5/24.
//

import Foundation
import SwiftUI

class NotificationTemplateString: ObservableObject {
    
    static let _shared = NotificationTemplateString()
    
    static func shared() -> NotificationTemplateString {
        return _shared
    }
    
    @Published var alert: Bool = false
    @Published var templates: [Item] = []
    //@Published var templateList:[ViewNotificationManager] = []
    @Published var templateList: [String] = []
    
    @AppStorage("notificationPaused") var notificationPaused: Bool = false
    @AppStorage("notificationTimePaused") var notificationTimePaused: Bool = false
    @AppStorage("flagTitle") var flagTitle: Bool = false
    @AppStorage("flagDomain") var flagDomain: Bool = false
    @AppStorage("flagTemplate") var flagTemplate: Bool = false
    @AppStorage("templateString")  var templateString: String = ""
    
    @AppStorage("apnTitle") var apnTitle: String = ""
    @AppStorage("apnDomain") var apnDomain: String = ""
    @AppStorage("apnTemplate") var apnTemplate: String = ""
  
    init(){
         
        let sub = templateString.split(separator: "::")
        for template in sub {
            let item = Item(id: UUID(), template: String(template).trimmingCharacters(in: .whitespaces))
            templates.append(item)
        }
    }
    
    func pushTemplate(id: UUID, template: String) {
         
        flagTemplate = false
        let found = templates.filter{$0.id == id}
        if found.count == 0 {
            let item = Item(id: id, template: template.trimmingCharacters(in: .whitespaces))
            templates.append(item)
        } else {
            //if let index:Int = self.templates.index(where: {$0.id == id}) {//changed form index
            if let index:Int = self.templates.firstIndex(where: {$0.id == id}) {//changed form index
                self.templates.remove(at: index)
                
                let item = Item(id: id, template: template)
                templates.append(item)
            }
        }
    }
    
    func buildTemplateString() -> String {
        
        templateString = ""
        for template in templates {
            
            if !template.template.isEmpty{
                templateString += "\(template.template) :: "
            }
        }
        
        if templateString.hasSuffix(":: ") {
            
            let startIndex = templateString.index(templateString.startIndex, offsetBy: 0)
            let endIndex = templateString.index(templateString.endIndex, offsetBy: -3)
            let range = startIndex..<endIndex
            let substring = templateString[range] 
            templateString = String(substring)
        }
         
        return templateString
    }
    
    func delayText() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.alert = false
        }
    }
    
 
}

@MainActor
extension NotificationTemplateString {

    /// Call this from MQTTState.setReceivedMessage() when you receive a template payload.
    /// Pass ONLY the payload portion (after "viewu_device_event::::template::::").
    func applyTemplatePayloadFromMQTT(newTemplateString: String) {
        let trimmed = newTemplateString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Persist raw payload for debugging/back-compat
        self.templateString = trimmed

        // Empty payload => clear
        guard !trimmed.isEmpty else {
            self.templateList = []
            self.templates = []
            return
        }

        // Split into individual templates (support both delimiters you’ve used)
        let pieces: [String]
        if trimmed.contains(";;;") {
            pieces = trimmed.components(separatedBy: ";;;")
        } else if trimmed.contains("::") {
            pieces = trimmed.components(separatedBy: "::")
        } else {
            pieces = [trimmed]
        }

        // Canonicalize + de-dupe (preserve order)
        func canonical(_ raw: String) -> String {
            raw.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ",")
        }

        var seen = Set<String>()
        let list = pieces
            .map { canonical($0) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }

        // Update the list of raw template strings
        self.templateList = list

        // OPTIONAL but recommended: keep `templates: [Item]` in sync too
        // (so your existing buildTemplateString()/pushTemplate() logic doesn’t drift)
        self.templates = list.map { Item(id: UUID(), template: $0) }

        // If the server just told us the current set, the UI “synced” state is true
        self.flagTemplate = true
    }
}
 

@MainActor
extension NotificationTemplateString {
    func clearTemplateList() {
        templateList = []
        templates = []          // optional, if you want `templates` cleared too
        templateString = ""     // optional, if you want storage cleared too
        //flagTemplate = false    // optional, depending on your UI semantics
    }
}


struct Item {
    let id: UUID
    let template: String
}

class NotificationTemplate: ObservableObject{
    
    @Published var templateString = ""
    
    @Published var cameras: [ItemState] = []
    @Published var labels: [ItemState] = []
    @Published var currentZones: [ItemState] = []
    @Published var enteredZones: [ItemState] = []
    @Published var types: [ItemState] = []
    
    let _new = NotificationTemplateString()
    
    func new() -> NotificationTemplateString {
        return _new
    }
 
    func setCameras(items: [String : Cameras2]){
        
        cameras.removeAll()
        
        for (name, _) in items{
            let itemState = ItemState(id: UUID(), name: name, state: false)
            cameras.append(itemState)
        }
    }
    
    func setLabels(items: [String : Cameras2]){
        
        labels.removeAll()
        
        for (_, value) in items{
            let tmp = value.objects.filters
            
            for obj in tmp{
                 
                let found = labels.filter{$0.name == obj.key}
                
                if found.count == 0 {
                    let itemState = ItemState(id: UUID(), name: obj.key, state: false)
                    labels.append(itemState)
                } 
            }
        } 
    }
    
    func setZones(items: [String : Cameras2]){
        
        currentZones.removeAll()
        enteredZones.removeAll()
        
        for (_, value) in items{
            for zone in value.zones {
                 
                let itemState = ItemState(id: UUID(), name: zone.key, state: false)
                currentZones.append(itemState)
                enteredZones.append(itemState) 
            }
        }
    }
    
    func setTypes(){
        
        types.removeAll()
        let new = ItemState(id: UUID(), name: "new", state: false)
        let update = ItemState(id: UUID(), name: "update", state: false)
        let end = ItemState(id: UUID(), name: "end", state: false)
        types.append(new)
        types.append(update)
        types.append(end)
    }
    
    struct ItemState: Hashable {
        let id: UUID
        let name: String
        var state: Bool
    }
}
