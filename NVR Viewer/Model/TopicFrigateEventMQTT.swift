//
//  TopicFrigateEventMQTT.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/4/24.
//

import Foundation

struct TopicFrigateEventHeaderMQTT: Codable, Hashable {
    let before: TopicFrigateEventMQTT
    let after: TopicFrigateEventMQTT
    let type: String
}

struct TopicFrigateEventMQTT: Codable, Hashable, Identifiable {
    
    let id: String
    let camera: String
    let frame_time: Double
    //let snapshot
    let label: String?
    let sub_label: String?
    let top_score: Double
    let false_positive: Bool
    let start_time: Double
    let end_time: Double?
    let score: Double
    let box: [Int]
    let area: Int
    let ratio: Double
    let region: [Int]
    let stationary: Bool
    let motionless_count: Int
    let position_changes: Int
    let current_zones: [String?]
    let entered_zones: [String?]
    let has_clip: Bool
    //let attribute
    //let current_attributes
}

// MARK: - Remove
////
////  TopicFrigateEventMQTT.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 6/4/24.
////
//
//import Foundation
//
//struct TopicFrigateEventHeaderMQTT: Codable, Hashable {
//    let before: TopicFrigateEventMQTT
//    let after: TopicFrigateEventMQTT
//    let type: String
//}
//
//struct TopicFrigateEventMQTT: Codable, Hashable {
//    
//    let id: String
//    let camera: String
//    let frame_time: Double
//    //let snapshot
//    let label: String?
//    let sub_label: String?
//    let top_score: Double
//    let false_positive: Bool
//    let start_time: Double
//    let end_time: Double?
//    let score: Double
//    let box: [Int]
//    let area: Int
//    let ratio: Double
//    let region: [Int]
//    let stationary: Bool
//    let motionless_count: Int
//    let position_changes: Int
//    let current_zones: [String?]
//    let entered_zones: [String?]
//    let has_clip: Bool
//    //let attribute
//    //let current_attributes
//}
//
