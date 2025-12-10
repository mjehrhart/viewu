//
//  NVRConfigurationHTTP.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/28/24.
//

import Foundation

/// Top-level HTTP response containing a list of NVR events.
struct EventsHTTP: Codable {
    let events: [NVRConfigurationHTTP]
}

/// Represents a single NVR HTTP event as returned by the backend.
struct NVRConfigurationHTTP: Codable, Hashable, Identifiable {
    /// Unique event identifier (also satisfies Identifiable.id)
    let id: String
    
    /// Camera name or identifier
    let camera: String
    
    /// Unix epoch seconds when the event started
    let start_time: Double
    
    /// Unix epoch seconds when the event ended (if known)
    let end_time: Double?
    
    /// Primary label (e.g. "person", "car")
    let label: String
    
    /// Optional sub-label from backend
    let sub_label: String?
    
    /// Optional list of Frigate zones this event belongs to
    let zones: [String]?
}
