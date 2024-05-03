//
//  ImageContainer.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/4/24.
//

import Foundation
import SwiftData

@Model
class ImageContainer: Hashable {
    @Attribute(.unique) var name: String 
    var url: String
    var date: Double
    var camera: String
    var label: String?
    var endPoints: Data?
    
    init(name: String, url: String, date: Double, camera: String, label: String? = nil, endPoints: Data? = nil) {
        self.name = name
        self.url = url
        self.date = date
        self.camera = camera
        self.label = label
        self.endPoints = endPoints
    }
}
