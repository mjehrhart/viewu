//
//  MQTTManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation

import CocoaMQTT
import Combine
import UserNotifications

@MainActor final class MQTTManager: ObservableObject {
    
    private var mqttClient: CocoaMQTT?
    private var identifier: String!
    private var topic: String!
  
    @Published var isAnonymous: Bool = UserDefaults.standard.bool(forKey: "mqttIsAnonUser")
    @Published var ip: String = UserDefaults.standard.string(forKey: "mqttIPAddress") ?? "127.0.0.1"
    @Published var port: String = UserDefaults.standard.string(forKey: "mqttPortAddress") ?? "1883"
    @Published var user: String = UserDefaults.standard.string(forKey: "mqttUser") ?? ""
    @Published var password: String = UserDefaults.standard.string(forKey: "mqttPassword") ?? ""

    var fcm: String = UserDefaults.standard.string(forKey: "fcm") ?? "0"
    
    @Published var currentAppState = MQTTAppState()
    private var anyCancellable: AnyCancellable?
     
    private init() {
        // Workaround to support nested Observables, without this code changes to state is not propagated
        anyCancellable = currentAppState.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
 
    private static let _shared = MQTTManager()
 
    class func shared() -> MQTTManager {
        return _shared
    }

    func initializeMQTT() {
          
        if mqttClient != nil {
            mqttClient = nil
        }
        
        self.identifier = UUID().uuidString
        let id = "viewu_\(self.identifier ?? "RandomIDGoesHere")_" + String(ProcessInfo().processIdentifier)
 
        if let number = UInt16(port) {
            mqttClient = CocoaMQTT(clientID: id, host: ip, port: number)
        }
         
        if !isAnonymous {
            mqttClient?.username = self.user
            mqttClient?.password = self.password
        }
        
        mqttClient?.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
        mqttClient?.keepAlive = 60
        mqttClient?.delegate = self
        //
        mqttClient?.autoReconnect = true
        mqttClient?.autoReconnectTimeInterval = 1
        mqttClient?.cleanSession = false
        //mqttClient?.enableSSL = true
        //mqttClient?.allowUntrustCACertificate = true
        //mqttClient?.logLevel = .debug
        //mqttClient?.ping() //test this out
    }
 
    func connect() {
        if let success = mqttClient?.connect(), success {
            currentAppState.setAppConnectionState(state: .connecting) //connecting
        } else {
            currentAppState.setAppConnectionState(state: .disconnected)
        }
    }

    func subscribe(topic: String) {
        self.topic = topic
        print("subscribe", topic)
        mqttClient?.subscribe(topic, qos: .qos1)
    }

    func publish(topic: String, with message: String) { 
        mqttClient?.publish(topic, withString: message, qos: .qos1)
    }

    func disconnect() {
        mqttClient?.disconnect()
    }

    /// Unsubscribe from a topic
    func unSubscribe(topic: String) {
        mqttClient?.unsubscribe(topic)
    }

    /// Unsubscribe from a topic
    func unSubscribeFromCurrentTopic() {
        mqttClient?.unsubscribe(topic)
    }
     
    func isSubscribed() -> Bool {
       return currentAppState.appConnectionState.isSubscribed
    }
    
    func isConnected() -> Bool {
        return currentAppState.appConnectionState.isConnected
    }
     
    func connectionStateMessage() -> String {
        return currentAppState.appConnectionState.description
    }
    
    func setAnonymous(anonymous: Bool ){
        self.isAnonymous = anonymous
    }
    
    func setIP(ip: String ){
        self.ip = ip
    }
    
    func setPort( port: String ){
        self.port = port
    }
    
    func setCredentials(user: String, password: String){
        self.user = user
        self.password = password
    }
}

extension MQTTManager: CocoaMQTTDelegate {
      
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .connectedSubscribed)
        }
    }
    
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
            //-currentAppState.clearData()
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        Task { @MainActor in 
            
            if ack == .accept {
                currentAppState.setAppConnectionState(state: .connected)
                mqttClient?.subscribe("frigate/events")
                mqttClient?.subscribe("viewu/pairing")
            }
        }
    }
     
    //1 [4,
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        Task { @MainActor in
            let _ = message.string.description
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        Task { @MainActor in
        }
    }
    //2
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        Task { @MainActor in
            currentAppState.setReceivedMessage(text: message.string.description)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
        //-currentAppState.clearData()
    }
    
    nonisolated func mqttDidPing(_ mqtt: CocoaMQTT) {
        Task { @MainActor in
        }
    }

    nonisolated func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        Task { @MainActor in
        }
    }

    nonisolated func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .disconnected)
        }
    }
}

 
