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
    @Published var cameras = ["all", "front", "side"]
    
    @Published var selectedObject: String = "all"
    @Published var objects = ["all", "bird", "backpack", "dog", "person"]
    
    @Published var selectedZone: String = "all"
    @Published var zones = ["all", "front", "back", "side", "pool"]
    
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
}
