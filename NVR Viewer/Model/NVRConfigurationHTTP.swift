//
//  NVRConfigurationHTTP.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/28/24.
//

import Foundation

struct EventsHTTP: Codable {
    let events : [NVRConfigurationHTTP]
}

struct NVRConfigurationHTTP: Codable, Hashable  {
    let camera: String
    let end_time : Double
    let id: String
    let label: String
    let start_time: Double
    let sub_label: String?
    let zones: [String]?
}
