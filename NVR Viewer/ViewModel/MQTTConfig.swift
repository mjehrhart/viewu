//
//  MQTTConfig.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/3/24.
//

import Foundation
  
class MQTTConfig {
    
    @Published var isAnonymous: Bool = UserDefaults.standard.bool(forKey: "mqttIsAnonUser")
    @Published var url: String = UserDefaults.standard.string(forKey: "mqttIPAddress") ?? "127.0.0.1"
    @Published var port: String = UserDefaults.standard.string(forKey: "mqttPortAddress") ?? "1883"
    @Published var user: String = UserDefaults.standard.string(forKey: "mqttUser") ?? ""
    @Published var password: String = UserDefaults.standard.string(forKey: "mqttPassword") ?? ""
      
    static let _shared = MQTTConfig()
    
    static func shared() -> MQTTConfig {
        return _shared
    }
    
    func setAnonymous(anonymous: Bool){
        self.isAnonymous = anonymous
    }
    func setUser(user: String) {
        self.user = user
    }
    func setPassword(password: String) {
        self.password = password
    }
    func setIP(ip:String) {
        self.url = ip
    } 
    func setPort(port:String) {
        self.port = port
    }
}
