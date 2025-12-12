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
     
    @Published var list3: [EventMeta3] = []
    
    static let _shared = EndpointOptionsSuper()
    
    static func shared() -> EndpointOptionsSuper {
        return _shared
    }
    
    func addBlank() {
        
        let x = EventMeta3()
        x.sid = 0 //5/26
        x.type = ""                 //no
        x.camera = ""               // yes
        x.cameraName = ""           // yes
        x.frameTime = 0.0           // maybe
        x.debug = ""                // yes
        x.id  = "\(UUID.init())"    // yes
        x.image = ""                // yes
        x.label = ""                // yes
        x.m3u8 = ""                 // yes
        x.mp4 = ""                  // yes
        x.score = 0.0               // maybe
        x.snapshot  = ""            // yes
        x.thumbnail  = ""           // yes
        x.transportType = "blank"   // yes
        x.sublabel = ""             // yes
        x.currentZones = ""         // no
        x.enteredZones = ""         // yes
        list3.append(x)
    }
    
    final class EventMeta3: ObservableObject, Identifiable {
        //API Info
        var thumbnail: String?
        var snapshot: String?
        var m3u8: String?
        var mp4: String?
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
        var sublabel: String?
        var currentZones: String?
        var enteredZones: String?
        
        //Misc
        var transportType: String?
        var sid: Int64?
        var frigatePlus: Bool?
    } 
}


struct EndpointOptions: Hashable, Codable, Identifiable {
    
    //API Info
    var thumbnail: String?
    var snapshot: String?
    var m3u8: String?
    var mp4: String?
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
    var sublabel: String?
    var currentZones: String?
    var enteredZones: String?
    
    //Misc
    var transportType: String?
    var sid: Int64?
    var frigatePlus: Bool?
}
