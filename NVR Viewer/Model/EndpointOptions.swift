//
//  EndpointOptions.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation
 
@MainActor
final class EndpointOptionsSuper: ObservableObject { // Codable,
    
    var list: [EndpointOptions] = []
    
    @Published var list2: [EventMeta] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var list3: [EventMeta3] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    static let _shared = EndpointOptionsSuper()
    
    static func shared() -> EndpointOptionsSuper {
        return _shared
    }
    
    func addBlank() {
        
        let x = EventMeta3()
        x.type = "new"
        x.camera = ""
        x.cameraName = ""
        x.frameTime = 0.0
        x.debug = ""
        x.id  = "\(UUID.init())"
        x.image = ""
        x.label = ""
        x.m3u8 = ""
        x.score = 0.0
        x.snapshot  = ""
        x.thumbnail  = ""
        x.transportType = "blank"
        list3.append(x)
    }
    
    class EventMeta3: ObservableObject, Identifiable {
        //API Info
        var thumbnail: String?
        var snapshot: String?
        var m3u8: String?
        var camera: String?
        var debug: String?
        var image: String?
        
        //Meta Info
        var id: String?
        var type: String?
        var cameraName: String?
        var score: Double?
        var frameTime: Double?
        var label: String?
        
        //Misc
        var transportType: String?
    }
    
    struct EventMeta: Identifiable,Equatable, Hashable {
        //API Info
        var thumbnail: String?
        var snapshot: String?
        var m3u8: String?
        var camera: String?
        var debug: String?
        var image: String?
        
        //Meta Info
        var id: String?
        var type: String?
        var cameraName: String?
        var score: Double?
        var frameTime: Double?
        var label: String?
        
        //Misc
        var transportType: String?
    }
}


struct EndpointOptions: Hashable, Codable, Identifiable {
    
    //API Info
    var thumbnail: String?
    var snapshot: String?
    var m3u8: String?
    var camera: String?
    var debug: String?
    var image: String?
    
    //Meta Info
    var id: String?
    var type: String?
    var cameraName: String?
    var score: Double?
    var frameTime: Double?
    var label: String?
    
    //Misc
    var transportType: String?
}
