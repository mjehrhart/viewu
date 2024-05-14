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
    
    //@Published var endDate = Date()
    //Add 1 future day so the app can search til midnight of today
    @Published var endDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
    //Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents)!
    
    @Published var startDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
    
    func reset() {
        
        selectedCamera = "all"
        selectedObject = "all"
        selectedZone = "all"
        
        startDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
        endDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
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
