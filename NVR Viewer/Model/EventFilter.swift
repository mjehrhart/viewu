//
//  EventFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import Foundation

class EventFilter: ObservableObject{
    
    static let _shared = EventFilter()
 
    static func shared() -> EventFilter {
        return _shared
    }
 
    @Published var selectedCamera: String = "all"
    @Published var cameras = ["all"]
    
    @Published var selectedObject: String = "all"
    @Published var objects = ["all"]
    
    @Published var selectedZone: String = "all"
    @Published var zones = ["all"]
    
    @Published var selectedType: String = "all"
    @Published var types = ["all", "new", "end", "update", "background", "ctask", "scenePhase"]
     
    //Add 1 future day so the app can search til midnight of today
    @Published var endDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
    @Published var startDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
    
    func reset() {
        
        selectedCamera = "all"
        selectedObject = "all"
        selectedZone = "all"
        selectedType = "all"
        
        startDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
        endDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
    }
    
    func setZones(items: [String : Cameras]){
         
        zones.removeAll()
        zones.append("all")
        
        for (name, value) in items{ 
            for zone in value.zones.keys {
                zones.append(zone)
            }
        }
    }
    
    func setCameras(items: [String : Cameras]){
        
        cameras.removeAll()
        cameras.append("all")
        
        for (name, value) in items{
            cameras.append(name)
        } 
    }
    
    func setObject(items: [String : Cameras]){
        
        objects.removeAll()
        objects.append("all")
        
        for (name, value) in items{
            let tmp = value.objects.filters
            
            for obj in tmp{
                 
                if !objects.contains(obj.key){
                    objects.append(obj.key)
                }
            }
        }
    }
      
}
