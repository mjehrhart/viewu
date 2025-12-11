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

@MainActor
final class MQTTManager: ObservableObject {

    // MARK: - Singleton

    private static let _shared = MQTTManager()
    class func shared() -> MQTTManager { _shared }

    // MARK: - MQTT

    private var mqttClient: CocoaMQTT?
    private var identifier: String = UUID().uuidString
    private var topic: String?

    // MARK: - Connection settings (backed by UserDefaults)

    @Published var isAnonymous: Bool =
        UserDefaults.standard.bool(forKey: "mqttIsAnonUser")

    @Published var ip: String =
        UserDefaults.standard.string(forKey: "mqttIPAddress") ?? "127.0.0.1"

    @Published var port: String =
        UserDefaults.standard.string(forKey: "mqttPortAddress") ?? "1883"

    @Published var user: String =
        UserDefaults.standard.string(forKey: "mqttUser") ?? ""

    @Published var password: String =
        UserDefaults.standard.string(forKey: "mqttPassword") ?? ""

    var fcm: String =
        UserDefaults.standard.string(forKey: "fcm") ?? "0"

    // MARK: - State

    @Published var currentAppState = MQTTAppState()

    private var anyCancellable: AnyCancellable?

    // MARK: - Init

    private init() {
        // Propagate changes from nested ObservableObject
        anyCancellable = currentAppState.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Setup

    /// Explicit helper to reset the connection state from the UI
    /// so we don't show stale "Connected" while reconfiguring.
    func resetConnectionState() {                               // CHANGED
        currentAppState.setAppConnectionState(state: .disconnected)
    }

    func initializeMQTT() {

        // Always start from a clean state for a new config         // CHANGED
        currentAppState.setAppConnectionState(state: .disconnected)

        // Tear down previous client if any
        mqttClient?.disconnect()
        mqttClient = nil

        // Basic validation of broker address and port              // CHANGED
        let trimmedIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIP.isEmpty else {
            // Invalid / empty host; stay disconnected
            return
        }

        guard let portNumber = UInt16(port) else {
            // Invalid port, mark disconnected and bail
            return
        }

        let pid = ProcessInfo.processInfo.processIdentifier
        let clientID = "viewu_\(identifier)_\(pid)"

        let client = CocoaMQTT(clientID: clientID, host: trimmedIP, port: portNumber)

        if !isAnonymous {
            client.username = user
            client.password = password
        }

        client.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
        client.keepAlive = 60
        client.delegate = self
        client.autoReconnect = true
        client.autoReconnectTimeInterval = 1
        client.cleanSession = false
        // client.enableSSL = true
        // client.allowUntrustCACertificate = true
        // client.logLevel = .debug

        mqttClient = client
    }

    // MARK: - Public API

    func connect() {
        guard let client = mqttClient else {
            currentAppState.setAppConnectionState(state: .disconnected)
            return
        }

        if client.connect() {
            currentAppState.setAppConnectionState(state: .connecting)
        } else {
            currentAppState.setAppConnectionState(state: .disconnected)
        }
    }

    func subscribe(topic: String) {
        self.topic = topic
        mqttClient?.subscribe(topic, qos: .qos1)
    }

    func publish(topic: String, with message: String) {
        mqttClient?.publish(topic, withString: message, qos: .qos1)
    }

    func disconnect() {
        mqttClient?.disconnect()
    }

    /// Unsubscribe from a specific topic
    func unSubscribe(topic: String) {
        mqttClient?.unsubscribe(topic)
    }

    /// Unsubscribe from the last subscribed topic
    func unSubscribeFromCurrentTopic() {
        guard let topic = topic else { return }
        mqttClient?.unsubscribe(topic)
    }

    func isSubscribed() -> Bool {
        currentAppState.appConnectionState.isSubscribed
    }

    func isConnected() -> Bool {
        currentAppState.appConnectionState.isConnected
    }

    func connectionStateMessage() -> String {
        currentAppState.appConnectionState.description
    }

    // MARK: - Mutators

    func setAnonymous(anonymous: Bool) {
        isAnonymous = anonymous
    }

    func setIP(ip: String) {
        self.ip = ip
    }

    func setPort(port: String) {
        self.port = port
    }

    func setCredentials(user: String, password: String) {
        self.user = user
        self.password = password
    }
}

// MARK: - CocoaMQTTDelegate

extension MQTTManager: CocoaMQTTDelegate {

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didSubscribeTopics success: NSDictionary,
        failed: [String]
    ) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .connectedSubscribed)
        }
    }

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didUnsubscribeTopics topics: [String]
    ) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
            // currentAppState.clearData()
        }
    }

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didConnectAck ack: CocoaMQTTConnAck
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            if ack == .accept {
                currentAppState.setAppConnectionState(state: .connected)
                mqttClient?.subscribe("frigate/events")
                mqttClient?.subscribe("viewu/pairing")
            } else {
                currentAppState.setAppConnectionState(state: .disconnected)
            }
        }
    }

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didPublishMessage message: CocoaMQTTMessage,
        id: UInt16
    ) {
        // No-op for now
    }

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didPublishAck id: UInt16
    ) {
        // No-op for now
    }

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didReceiveMessage message: CocoaMQTTMessage,
        id: UInt16
    ) {
        Task { @MainActor in
            currentAppState.setReceivedMessage(text: message.string ?? "")
        }
    }

    nonisolated func mqtt(
        _ mqtt: CocoaMQTT,
        didUnsubscribeTopic topic: String
    ) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
            // currentAppState.clearData()
        }
    }

    nonisolated func mqttDidPing(_ mqtt: CocoaMQTT) {
        // No-op
    }

    nonisolated func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // No-op
    }

    nonisolated func mqttDidDisconnect(
        _ mqtt: CocoaMQTT,
        withError err: Error?
    ) {
        Task { @MainActor in
            currentAppState.setAppConnectionState(state: .disconnected)
        }
    }
}

