//
//  Enums.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation

// MARK: - Authentication

enum AuthType: String, Codable, CaseIterable {
    case none       = "None"
    case bearer     = "Bearer"
    case frigate    = "FrigatePort8971"
    case cloudflare = "CloudFlare"
    case custom     = "Custom"
    
    /// Human-readable label for UI.
    var description: String { rawValue }
}

extension AuthType {
    // These are useful for SwiftUI bindings to act like radio buttons.
    // Note: setting to `false` is intentionally a no-op.
    
    var isNone: Bool {
        get { self == .none }
        set { if newValue { self = .none } }
    }
    
    var isFrigate: Bool {
        get { self == .frigate }
        set { if newValue { self = .frigate } }
    }
    
    var isCustom: Bool {
        get { self == .custom }
        set { if newValue { self = .custom } }
    }
    
    var isBearer: Bool {
        get { self == .bearer }
        set { if newValue { self = .bearer } }
    }
    
    var isCloudFlare: Bool {
        get { self == .cloudflare }
        set { if newValue { self = .cloudflare } }
    }
}

// MARK: - NVR Connection State

enum NVRConnectionState {
    case connected
    case disconnected
    
    var description: String {
        switch self {
        case .connected:    return "Connected"
        case .disconnected: return "Disconnected"
        }
    }
    
    var isConnected: Bool {
        self == .connected
    }
}

// MARK: - MQTT Connection State

enum MQTTAppConnectionState {
    case connected
    case disconnected
    case connecting
    case connectedSubscribed
    case connectedUnSubscribed
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connectedSubscribed:
            return "Subscribed"
        case .connectedUnSubscribed:
            return "Connected Unsubscribed"
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected, .connectedSubscribed, .connectedUnSubscribed:
            return true
        case .disconnected, .connecting:
            return false
        }
    }
    
    /// Only `connected` counts as "connected on load" in your original logic.
    var isConnectedOnload: Bool {
        self == .connected
    }
    
    var isSubscribed: Bool {
        self == .connectedSubscribed
    }
}

// MARK: - Frigate API Endpoint

enum FrigateAPIEndpoint {
    case Thumbnail
    case Snapshot
    case M3U8
    case MP4
    case Image
    case Camera
    case Debug
}

// MARK: - Remove
////  Enums.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/1/24.
////
//
//import Combine
//import Foundation
//
//enum AuthType:  String, Codable, CaseIterable, RawRepresentable  {
//    
//    case none
//    case bearer
//    case frigate
//    case cloudflare
//    case custom
//    
//    var description: String {
//        switch self {
//        case .none:
//            return "None"
//        case .bearer:
//            return "Bearer"
//        case .frigate:
//            return "FrigatePort8971"
//        case .cloudflare:
//            return "CloudFlare"
//        case .custom:
//            return "Custom"
//        }
//    }
//}
//
//extension AuthType {
//    var isNone: Bool {
//        get { self == .none }
//        set { if newValue { self = .none } }
//    }
//    
//    var isFrigate: Bool {
//        get { self == .frigate }
//        set { if newValue { self = .frigate } }
//    }
//    
//    var isCustom: Bool {
//        get { self == .custom }
//        set { if newValue { self = .custom } }
//    }
//    
//    var isBearer: Bool {
//        get { self == .bearer }
//        set { if newValue { self = .bearer } }
//    }
//    
//    var isCloudFlare: Bool {
//        get { self == .cloudflare }
//        set { if newValue { self = .cloudflare } }
//    }
//}
//
//enum NVRConnectionState {
//    case connected
//    case disconnected
//    
//    var description: String {
//        switch self {
//        case .connected:
//            return "Connected"
//        case .disconnected:
//            return "Disconnected"
//        }
//    }
//}
//
//enum MQTTAppConnectionState {
//    case connected
//    case disconnected
//    case connecting
//    case connectedSubscribed
//    case connectedUnSubscribed
//
//    var description: String {
//        switch self {
//        case .connected:
//            return "Connected"
//        case .disconnected:
//            return "Disconnected"
//        case .connecting:
//            return "Connecting"
//        case .connectedSubscribed:
//            return "Subscribed"
//        case .connectedUnSubscribed:
//            return "Connected Unsubscribed"
//        }
//    }
//    var isConnected: Bool {
//        switch self {
//        case .connected, .connectedSubscribed, .connectedUnSubscribed:
//            return true
//        case .disconnected,.connecting:
//            return false
//        }
//    }
//    
//    var isConnectedOnload: Bool {
//        switch self {
//        case .connected:
//            return true
//        case .disconnected,.connecting, .connectedSubscribed, .connectedUnSubscribed:
//            return false
//        }
//    }
//    
//    var isSubscribed: Bool {
//        switch self {
//        case .connectedSubscribed:
//            return true
//        case .disconnected,.connecting, .connected,.connectedUnSubscribed:
//            return false
//        }
//    }
//}
//
//enum FrigateAPIEndpoint {
//    case Thumbnail
//    case Snapshot
//    case M3U8
//    case MP4
//    case Image
//    case Camera
//    case Debug
//}
//
