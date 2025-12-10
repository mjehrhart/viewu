//
//  MQTTConfig.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/3/24.
//

import Foundation
import Combine

final class MQTTConfig: ObservableObject {

    // MARK: - Singleton

    static let _shared = MQTTConfig()
    //static let shared = _shared   // convenience

    static func shared() -> MQTTConfig {
        return _shared
    }

    // MARK: - Stored properties (backed by UserDefaults)

    @Published var isAnonymous: Bool {
        didSet {
            UserDefaults.standard.set(isAnonymous, forKey: "mqttIsAnonUser")
        }
    }

    @Published var url: String {
        didSet {
            UserDefaults.standard.set(url, forKey: "mqttIPAddress")
        }
    }

    @Published var port: String {
        didSet {
            UserDefaults.standard.set(port, forKey: "mqttPortAddress")
        }
    }

    @Published var user: String {
        didSet {
            UserDefaults.standard.set(user, forKey: "mqttUser")
        }
    }

    @Published var password: String {
        didSet {
            UserDefaults.standard.set(password, forKey: "mqttPassword")
        }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        isAnonymous = defaults.bool(forKey: "mqttIsAnonUser")
        url         = defaults.string(forKey: "mqttIPAddress") ?? "127.0.0.1"
        port        = defaults.string(forKey: "mqttPortAddress") ?? "1883"
        user        = defaults.string(forKey: "mqttUser") ?? ""
        password    = defaults.string(forKey: "mqttPassword") ?? ""
    }

    // MARK: - Convenience setters (for existing call sites)

    func setAnonymous(anonymous: Bool) {
        isAnonymous = anonymous
    }

    func setUser(user: String) {
        self.user = user
    }

    func setPassword(password: String) {
        self.password = password
    }

    func setIP(ip: String) {
        self.url = ip
    }

    func setPort(port: String) {
        self.port = port
    }
}


// MARK: - Remove
////
////  MQTTConfig.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/3/24.
////
//
//import Foundation
//  
//class MQTTConfig {
//    
//    @Published var isAnonymous: Bool = UserDefaults.standard.bool(forKey: "mqttIsAnonUser")
//    @Published var url: String = UserDefaults.standard.string(forKey: "mqttIPAddress") ?? "127.0.0.1"
//    @Published var port: String = UserDefaults.standard.string(forKey: "mqttPortAddress") ?? "1883"
//    @Published var user: String = UserDefaults.standard.string(forKey: "mqttUser") ?? ""
//    @Published var password: String = UserDefaults.standard.string(forKey: "mqttPassword") ?? ""
//      
//    static let _shared = MQTTConfig()
//    
//    static func shared() -> MQTTConfig {
//        return _shared
//    }
//    
//    func setAnonymous(anonymous: Bool){
//        self.isAnonymous = anonymous
//    }
//    func setUser(user: String) {
//        self.user = user
//    }
//    func setPassword(password: String) {
//        self.password = password
//    }
//    func setIP(ip:String) {
//        self.url = ip
//    } 
//    func setPort(port:String) {
//        self.port = port
//    }
//}
