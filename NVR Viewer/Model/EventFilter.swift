//
//  EventFilter.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import Foundation

@MainActor
final class EventFilter: ObservableObject {
    
    static let _shared = EventFilter()
 
    static func shared() -> EventFilter {
        return _shared
    }
 
    @Published var selectedCamera: String = "all"
    @Published var cameras: [String] = ["all"]
    
    @Published var selectedObject: String = "all"
    @Published var objects: [String] = ["all"]
    
    @Published var selectedZone: String = "all"
    @Published var zones: [String] = ["all"]
    
    @Published var selectedType: String = "all"
    @Published var types: [String] = ["all", "new", "end", "update", "background", "ctask", "scenePhase"]
     
    // Add 1 future day so the app can search til midnight of today
    @Published var endDate: Date = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
    @Published var startDate: Date = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
    
    func reset() {
        selectedCamera = "all"
        selectedObject = "all"
        selectedZone = "all"
        selectedType = "all"
        
        startDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date()) ?? Date()
        endDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: Date()) ?? Date()
    }
    
    func setZones(items: [String: Cameras2]) {
        zones.removeAll()
        zones.append("all")
        
        for (_, value) in items {
            for zone in value.zones.keys {
                zones.append(zone)
            }
        }
    }
    
    // 11/08/2025 - changed Cameras to Cameras2
    func setCameras(items: [String: Cameras2]) {
        cameras.removeAll()
        cameras.append("all")
        
        for (name, _) in items {
            cameras.append(name)
        }
    }
    
    func setObject(items: [String: Cameras2]) {
        objects.removeAll()
        objects.append("all")
        
        for (_, value) in items {
            let tmp = value.objects.filters
            
            for obj in tmp {
                if !objects.contains(obj.key) {
                    objects.append(obj.key)
                }
            }
        }
    }
}
