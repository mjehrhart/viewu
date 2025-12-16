//
//  MQTTManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation
import CocoaMQTT
import Combine
import SwiftUI
import Security
import CryptoKit

@MainActor
final class MQTTManager: ObservableObject {

    // MARK: - Singleton

    private static let _shared = MQTTManager()
    class func shared() -> MQTTManager { _shared }

    // MARK: - Logging

    private enum LG {
        static let page = "MQTTManager"
    }

    // MARK: - Types

    enum ConnectionState: String {
        case disconnected
        case connecting
        case connected
    }

    enum MQTTMode: String {
        case direct
        case cloudflare
    }

    private enum Transport: String {
        case tcp
        case websocket
    }

    private struct ConnectionPlan {
        var mode: MQTTMode
        var transport: Transport
        var host: String
        var port: UInt16
        var wsPath: String
        var wsUseTLS: Bool
        var directUseTLS: Bool
        var allowInsecureTLS: Bool
        var headers: [String: String]
    }

    // Snapshot that nonisolated delegate callbacks can read safely enough for this use-case.
    // Written on MainActor during initializeMQTT(); read from delegate callbacks.
    private nonisolated(unsafe) var planSnapshot = ConnectionPlan(
        mode: .direct,
        transport: .tcp,
        host: "127.0.0.1",
        port: 1883,
        wsPath: "/mqtt",
        wsUseTLS: false,
        directUseTLS: false,
        allowInsecureTLS: false,
        headers: [:]
    )

    // MARK: - Keys

    private enum Keys {
        static let mqttIsAnonUser         = "mqttIsAnonUser"
        static let mqttIPAddress          = "mqttIPAddress"
        static let mqttPortAddress        = "mqttPortAddress"
        static let mqttUser               = "mqttUser"
        static let mqttPassword           = "mqttPassword"
        static let mqttTopic              = "mqttTopic"

        static let mqttUseWebSockets      = "mqttUseWebSockets"
        static let mqttWebSocketPath      = "mqttWebSocketPath"
        static let mqttWebSocketUseTLS    = "mqttWebSocketUseTLS"

        static let mqttUseCloudflareMQTT  = "mqttUseCloudflareMQTT"

        // NEW: only applies to DIRECT (non-Cloudflare) when TLS is used.
        static let mqttAllowSelfSignedTLS = "mqttAllowSelfSignedTLS"

        // Cloudflare Access creds (CANONICAL — MUST match ViewAuthCloudFlare + AuthCloudFlare)
        static let cloudFlareClientId     = "cloudFlareClientId"
        static let cloudFlareClientSecret = "cloudFlareClientSecret"

        // Legacy (migration only)
        static let legacyCloudFlareSecret = "cloudFlareSecret"
    }

    private let appGroupSuite = "group.com.viewu.app"

    // MARK: - MQTT

    private func secretFingerprint(_ secret: String) -> String {
        guard !secret.isEmpty else { return "missing" }
        let digest = SHA256.hash(data: Data(secret.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(12) + ""
    }

    private var mqttClient: CocoaMQTT?
    private var pendingMode: MQTTMode = .direct

    // MARK: - State (UI)

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var activeMode: MQTTMode = .direct

    // Keep your existing app-state object (your UI references this)
    let currentAppState = MQTTAppState()

    // MARK: - User-editable settings (persisted)

    @Published var isAnonymous: Bool {
        didSet { UserDefaults.standard.set(isAnonymous, forKey: Keys.mqttIsAnonUser) }
    }

    @Published var ip: String {
        didSet { UserDefaults.standard.set(ip, forKey: Keys.mqttIPAddress) }
    }

    @Published var port: String {
        didSet { UserDefaults.standard.set(port, forKey: Keys.mqttPortAddress) }
    }

    @Published var user: String {
        didSet { UserDefaults.standard.set(user, forKey: Keys.mqttUser) }
    }

    @Published var password: String {
        didSet { UserDefaults.standard.set(password, forKey: Keys.mqttPassword) }
    }

    @Published var topic: String {
        didSet { UserDefaults.standard.set(topic, forKey: Keys.mqttTopic) }
    }

    @Published var useWebSockets: Bool {
        didSet { UserDefaults.standard.set(useWebSockets, forKey: Keys.mqttUseWebSockets) }
    }

    @Published var webSocketPath: String {
        didSet { UserDefaults.standard.set(webSocketPath, forKey: Keys.mqttWebSocketPath) }
    }

    @Published var webSocketUseTLS: Bool {
        didSet { UserDefaults.standard.set(webSocketUseTLS, forKey: Keys.mqttWebSocketUseTLS) }
    }

    /// Settings toggle controls the selected/desired mode.
    /// Do NOT auto-reconnect here; call `applySettingsAndReconnect()` from Save.
    @Published var useCloudflareMQTT: Bool {
        didSet { UserDefaults.standard.set(useCloudflareMQTT, forKey: Keys.mqttUseCloudflareMQTT) }
    }

    /// NEW: Only used for DIRECT connections when TLS is in play (WSS or MQTTS).
    /// Never used for Cloudflare mode.
    @Published var allowSelfSignedTLS: Bool {
        didSet { UserDefaults.standard.set(allowSelfSignedTLS, forKey: Keys.mqttAllowSelfSignedTLS) }
    }

    // MARK: - Init

    private init() {
        let ud = UserDefaults.standard

        self.isAnonymous = ud.bool(forKey: Keys.mqttIsAnonUser)
        self.ip = ud.string(forKey: Keys.mqttIPAddress) ?? "127.0.0.1"
        self.port = ud.string(forKey: Keys.mqttPortAddress) ?? "1883"
        self.user = ud.string(forKey: Keys.mqttUser) ?? ""
        self.password = ud.string(forKey: Keys.mqttPassword) ?? ""
        self.topic = ud.string(forKey: Keys.mqttTopic) ?? "viewu/pairing"

        // IMPORTANT DEFAULT CHANGE:
        // Defaulting these to TRUE is what causes wss://<LAN-IP>:1883/mqtt and -1200.
        // Existing users keep their saved values; new/empty installs default to sane direct TCP.
        self.useWebSockets = ud.object(forKey: Keys.mqttUseWebSockets) as? Bool ?? false
        self.webSocketPath = ud.string(forKey: Keys.mqttWebSocketPath) ?? "/mqtt"
        self.webSocketUseTLS = ud.object(forKey: Keys.mqttWebSocketUseTLS) as? Bool ?? false

        self.useCloudflareMQTT = ud.bool(forKey: Keys.mqttUseCloudflareMQTT)
        self.allowSelfSignedTLS = ud.bool(forKey: Keys.mqttAllowSelfSignedTLS)

        self.pendingMode = useCloudflareMQTT ? .cloudflare : .direct
        self.activeMode = .direct
    }

    // MARK: - Compatibility setters (used by your Settings view)

    func setAnonymous(anonymous: Bool) { isAnonymous = anonymous }
    func setIP(ip: String) { self.ip = ip }
    func setPort(port: String) { self.port = port }
    func setCredentials(user: String, password: String) {
        self.user = user
        self.password = password
    }

    func setUseCloudflareMQTT(_ enabled: Bool) {
        useCloudflareMQTT = enabled
        Log.debug(page: LG.page, fn: "setUseCloudflareMQTT", "useCloudflareMQTT set to \(enabled)")
    }

    func setAllowSelfSignedTLS(_ enabled: Bool) {
        allowSelfSignedTLS = enabled
        Log.debug(page: LG.page, fn: "setAllowSelfSignedTLS", "allowSelfSignedTLS set to \(enabled)")
    }

    // MARK: - Public API

    func isConnected() -> Bool {
        connectionState == .connected
    }

    /// Call from "Save Connection"
    func applySettingsAndReconnect() {
        initializeMQTT()
        connect()
    }

    // MARK: - Connection lifecycle

    func initializeMQTT() {
        Log.debug(page: LG.page, fn: "initializeMQTT",
                  "Starting MQTT init. current client exists=\(mqttClient != nil)")

        // Tear down any existing client cleanly
        if let existing = mqttClient {
            Log.debug(page: LG.page, fn: "initializeMQTT", "Disconnecting previous MQTT client")
            existing.disconnect()
            mqttClient = nil
        }

        // Normalize inputs
        let host = normalizeHost(ip)
        let rawPort = parsePort(port)
        let path = normalizeWebSocketPath(webSocketPath)

        // Determine intended mode
        pendingMode = useCloudflareMQTT ? .cloudflare : .direct

        // Read + SYNC Cloudflare Access creds
        let cf = CloudflareAccessCreds.getAndSync()
        let cfId = cf.clientId
        let cfSecret = cf.clientSecret
        let cfSecretFP = secretFingerprint(cfSecret)

        let clientID = makeClientId()

        // Build a connection plan (this is the routing fix)
        let plan = buildPlan(
            mode: pendingMode,
            host: host,
            port: rawPort,
            wsPath: path,
            userWantsWebSockets: useWebSockets,
            userWantsWSTLS: webSocketUseTLS,
            allowSelfSignedTLS: allowSelfSignedTLS,
            cfId: cfId,
            cfSecret: cfSecret
        )

        // Publish snapshot for nonisolated delegate callbacks
        planSnapshot = plan

        Log.debug(
            page: LG.page,
            fn: "initializeMQTT",
            """
            Settings snapshot:
              ip(raw)=\(ip)
              host(normalized)=\(host)
              port(raw)=\(port)
              port(parsed)=\(rawPort)
              useWebSockets(user)=\(useWebSockets)
              webSocketPath(user)=\(webSocketPath)
              webSocketUseTLS(user)=\(webSocketUseTLS)
              allowSelfSignedTLS(user)=\(allowSelfSignedTLS)
              useCloudflareMQTT=\(useCloudflareMQTT)
              cfId=\(redact(cfId)) (\(cfId.count) chars) source=appGroup(\(appGroupSuite)):key=\(Keys.cloudFlareClientId) len=\(cfId.count)
              cfSecret=\(redact(cfSecret)) (\(cfSecret.count) chars) source=appGroup(\(appGroupSuite)):key=\(Keys.cloudFlareClientSecret) len=\(cfSecret.count)
              cfSecretFP=\(cfSecretFP)
              clientID=\(clientID)

            Effective plan:
              mode=\(plan.mode)
              transport=\(plan.transport)
              host=\(plan.host)
              port=\(plan.port)
              wsPath=\(plan.wsPath)
              wsUseTLS=\(plan.wsUseTLS)
              directUseTLS=\(plan.directUseTLS)
              allowInsecureTLS=\(plan.allowInsecureTLS)
              headers={\(describeHeaders(plan.headers))}
            """
        )

        // Build client
        let client: CocoaMQTT

        switch plan.transport {
        case .websocket:
            let scheme = plan.wsUseTLS ? "wss" : "ws"
            let fullWSURL = "\(scheme)://\(plan.host):\(plan.port)\(plan.wsPath)"
            Log.debug(page: LG.page, fn: "initializeMQTT",
                      "Configuring MQTT over WebSockets. url=\(fullWSURL)")

            let ws = CocoaMQTTWebSocket(uri: plan.wsPath)
            ws.enableSSL = plan.wsUseTLS
            ws.headers = plan.headers

            client = CocoaMQTT(clientID: clientID, host: plan.host, port: plan.port, socket: ws)

            #if DEBUG
            if let url = URL(string: fullWSURL) {
                wssProbe(url: url, headers: plan.headers, allowInsecureTLS: plan.allowInsecureTLS)
            }
            #endif

        case .tcp:
            Log.debug(page: LG.page, fn: "initializeMQTT",
                      "Configuring MQTT over direct TCP. host=\(plan.host) port=\(plan.port)")
            client = CocoaMQTT(clientID: clientID, host: plan.host, port: plan.port)

            if plan.directUseTLS {
                // CocoaMQTT supports enabling TLS directly via enableSSL. :contentReference[oaicite:2]{index=2}
                client.enableSSL = true

                // If user explicitly wants to allow self-signed / untrusted CA, enable that.
                // CocoaMQTT documents allowUntrustCACertificate for this use. :contentReference[oaicite:3]{index=3}
                client.allowUntrustCACertificate = plan.allowInsecureTLS
            }
        }

        // Common client configuration
        client.keepAlive = 60
        client.cleanSession = true
        client.autoReconnect = true
        client.autoReconnectTimeInterval = 2

        // Username/password only when not anonymous
        if !isAnonymous {
            let u = user.trimmingCharacters(in: .whitespacesAndNewlines)
            let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
            if !u.isEmpty { client.username = u }
            if !p.isEmpty { client.password = p }
        } else {
            client.username = nil
            client.password = nil
        }

        client.delegate = self
        mqttClient = client
    }

    func connect() {
        guard let client = mqttClient else {
            Log.error(page: LG.page, fn: "connect", "connect called but mqttClient is nil")
            return
        }

        connectionState = .connecting
        currentAppState.setAppConnectionState(state: .connecting)

        Log.debug(page: LG.page, fn: "connect",
                  "Attempting connect. host=\(client.host) port=\(client.port) clientID=\(client.clientID)")
        let ok = client.connect()
        Log.debug(page: LG.page, fn: "connect", "client.connect() returned \(ok)")
    }

    func disconnect() {
        mqttClient?.disconnect()
        connectionState = .disconnected
        currentAppState.setAppConnectionState(state: .disconnected)
    }

    // MARK: - Topics

    private let coreTopics: [(String, CocoaMQTTQoS)] = [
        ("frigate/events", .qos1),
        ("viewu/pairing", .qos1)
    ]

    private func subscribeCoreTopics(_ mqtt: CocoaMQTT) {
        Log.debug(page: LG.page, fn: "subscribeCoreTopics", "Auto-subscribing to core topics")
        for (t, qos) in coreTopics {
            mqtt.subscribe(t, qos: qos)
        }
    }

    func publish(topic: String, with payload: String) {
        guard let mqtt = mqttClient else { return }
        mqtt.publish(topic, withString: payload, qos: .qos1, retained: false)
    }

    func publish(_ payload: String, to topic: String? = nil) {
        publish(topic: topic ?? self.topic, with: payload)
    }

    // MARK: - Cloudflare creds debug helpers

    func debugDumpCloudflareAccessValues() {
        let appGroup = UserDefaults(suiteName: appGroupSuite)
        let standard = UserDefaults.standard

        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
                  "AppGroup available=\(appGroup != nil) suite=\(appGroupSuite)")

        let agId = appGroup?.string(forKey: Keys.cloudFlareClientId) ?? ""
        let agSecret = appGroup?.string(forKey: Keys.cloudFlareClientSecret) ?? ""
        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
                  "AppGroup: cloudFlareClientId=\(redact(agId)) (\(agId.count) chars) len=\(agId.count)")
        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
                  "AppGroup: cloudFlareClientSecret=\(redact(agSecret)) (\(agSecret.count) chars) len=\(agSecret.count)")

        let stId = standard.string(forKey: Keys.cloudFlareClientId) ?? ""
        let stSecret = standard.string(forKey: Keys.cloudFlareClientSecret) ?? ""
        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
                  "Standard: cloudFlareClientId=\(redact(stId)) (\(stId.count) chars) len=\(stId.count)")
        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
                  "Standard: cloudFlareClientSecret=\(stSecret.isEmpty ? "missing" : redact(stSecret)) len=\(stSecret.count)")
    }

    // MARK: - Routing / Plan Builder (THE FIX)

    private func buildPlan(
        mode: MQTTMode,
        host: String,
        port: UInt16,
        wsPath: String,
        userWantsWebSockets: Bool,
        userWantsWSTLS: Bool,
        allowSelfSignedTLS: Bool,
        cfId: String,
        cfSecret: String
    ) -> ConnectionPlan {

        var effectiveMode = mode
        var effectiveHost = host
        var effectivePort = port
        var effectiveWPath = wsPath

        // Start from user prefs (direct mode), then override/correct as needed
        var transport: Transport = userWantsWebSockets ? .websocket : .tcp
        var wsUseTLS = userWantsWSTLS
        var directUseTLS = false

        // Only direct mode may allow insecure TLS
        var allowInsecure = (effectiveMode == .direct) ? allowSelfSignedTLS : false

        var headers: [String: String] = [:]

        if effectiveMode == .cloudflare {
            // Cloudflare mode ALWAYS uses WebSockets + TLS + CF headers.
            transport = .websocket
            wsUseTLS = true
            allowInsecure = false
            headers["Sec-WebSocket-Protocol"] = "mqtt"

            // If user left port at 1883, they almost certainly meant "MQTT default" not "Cloudflare edge".
            // Cloudflare edge is typically 443 for wss.
            if effectivePort == 1883 {
                Log.warning(page: LG.page, fn: "buildPlan",
                            "Cloudflare MQTT enabled but port=1883. Auto-routing to port=443 for wss.")
                effectivePort = 443
            }

            if effectiveWPath.isEmpty { effectiveWPath = "/mqtt" }

            if cfId.isEmpty || cfSecret.isEmpty {
                Log.warning(page: LG.page, fn: "buildPlan",
                            "Cloudflare MQTT enabled but CF creds missing. idLen=\(cfId.count) secretLen=\(cfSecret.count)")
            }
            if !cfId.isEmpty { headers["CF-Access-Client-Id"] = cfId }
            if !cfSecret.isEmpty { headers["CF-Access-Client-Secret"] = cfSecret }

            return ConnectionPlan(
                mode: effectiveMode,
                transport: transport,
                host: effectiveHost,
                port: effectivePort,
                wsPath: effectiveWPath,
                wsUseTLS: wsUseTLS,
                directUseTLS: false,
                allowInsecureTLS: allowInsecure,
                headers: headers
            )
        }

        // DIRECT mode (VPN/LAN/etc.)
        if transport == .websocket {
            headers["Sec-WebSocket-Protocol"] = "mqtt"

            // Critical auto-fix:
            // If user selected WSS but is pointing at port 1883, that’s almost always "plain MQTT",
            // and iOS will throw -1200 during the TLS handshake (wss -> https upgrade).
            if effectivePort == 1883 && wsUseTLS == true {
                Log.warning(page: LG.page, fn: "buildPlan",
                            "Direct mode: detected wss://\(effectiveHost):1883\(effectiveWPath). Auto-routing to direct TCP on 1883 (plain MQTT).")
                transport = .tcp
                wsUseTLS = false
            }
        }

        // If we ended up on TCP, optionally infer TLS for the common MQTTS port.
        if transport == .tcp {
            // Common convention: 8883 = MQTT over TLS
            if effectivePort == 8883 {
                directUseTLS = true
            }
        }

        return ConnectionPlan(
            mode: effectiveMode,
            transport: transport,
            host: effectiveHost,
            port: effectivePort,
            wsPath: effectiveWPath,
            wsUseTLS: wsUseTLS,
            directUseTLS: directUseTLS,
            allowInsecureTLS: allowInsecure,
            headers: headers
        )
    }

    // MARK: - Private helpers

    private func normalizeHost(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "https://", with: "")
        s = s.replacingOccurrences(of: "http://", with: "")
        s = s.replacingOccurrences(of: "wss://", with: "")
        s = s.replacingOccurrences(of: "ws://", with: "")

        if let slash = s.firstIndex(of: "/") {
            s = String(s[..<slash])
        }
        if let colon = s.firstIndex(of: ":") {
            s = String(s[..<colon])
        }
        return s
    }

    private func parsePort(_ raw: String) -> UInt16 {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return UInt16(trimmed) ?? 1883
    }

    private func normalizeWebSocketPath(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return "/mqtt" }
        if !s.hasPrefix("/") { s = "/" + s }
        return s
    }

    private func makeClientId() -> String {
        let uuid = UUID().uuidString
        let rand = Int.random(in: 10000...99999)
        return "viewu_\(uuid)_\(rand)"
    }

    private func redact(_ s: String) -> String {
        guard s.count > 10 else { return s }
        return "\(s.prefix(6))…\(s.suffix(6))"
    }

    private func describeHeaders(_ headers: [String: String]) -> String {
        headers.keys.sorted().map { key in
            "\(key)=len(\(headers[key]?.count ?? 0))"
        }.joined(separator: ", ")
    }

    #if DEBUG
    private final class WSSProbeDelegate: NSObject, URLSessionDelegate {
        let allowInsecureTLS: Bool
        init(allowInsecureTLS: Bool) { self.allowInsecureTLS = allowInsecureTLS }

        func urlSession(_ session: URLSession,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let trust = challenge.protectionSpace.serverTrust
            else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            if allowInsecureTLS {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }

    private func wssProbe(url: URL, headers: [String: String], allowInsecureTLS: Bool) {
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        Log.debug(page: LG.page, fn: "wssProbe",
                  "Starting URLSessionWebSocketTask probe. url=\(url.absoluteString) headers={\(describeHeaders(headers))} allowInsecureTLS=\(allowInsecureTLS)")

        let delegate = WSSProbeDelegate(allowInsecureTLS: allowInsecureTLS)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        let task = session.webSocketTask(with: request)
        task.resume()

        task.sendPing { [weak task] error in
            Task { @MainActor in
                if let error {
                    Log.error(page: LG.page, fn: "wssProbe", "Ping failed: \(error)")
                } else {
                    Log.debug(page: LG.page, fn: "wssProbe", "Ping succeeded. WSS handshake appears OK.")
                }
                task?.cancel(with: .goingAway, reason: nil)
            }
        }
    }
    #endif

    private func handleDisconnect(_ mqtt: CocoaMQTT, error: Error?) {
        guard mqtt === mqttClient else { return }

        if let error {
            Log.error(page: LG.page, fn: "mqttDidDisconnect", "Disconnected with error: \(error)")
        } else {
            Log.warning(page: LG.page, fn: "mqttDidDisconnect", "Disconnected (no error provided)")
        }

        connectionState = .disconnected
        currentAppState.setAppConnectionState(state: .disconnected)
    }
}

// MARK: - CocoaMQTTDelegate

extension MQTTManager: CocoaMQTTDelegate {

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didConnect", "Socket connected. host=\(host) port=\(port)")
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didStateChangeTo", "State changed -> \(state)")

            switch state {
            case .connected:
                connectionState = .connected
            case .connecting:
                connectionState = .connecting
            default:
                connectionState = .disconnected
            }
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }

            Log.debug(page: LG.page, fn: "didConnectAck", "ConnAck received: \(ack)")

            if ack == .accept {
                activeMode = pendingMode
                connectionState = .connected
                currentAppState.setAppConnectionState(state: .connected)
                subscribeCoreTopics(mqtt)
            } else {
                connectionState = .disconnected
                currentAppState.setAppConnectionState(state: .disconnected)
            }
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didSubscribeTopics", "Subscribed success=\(success) failed=\(failed)")
            currentAppState.setAppConnectionState(state: .connectedSubscribed)
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didUnsubscribeTopics", "Unsubscribed topics=\(topics)")
            currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didPublishMessage",
                      "Published message. id=\(id) topic=\(message.topic) qos=\(message.qos) payloadLen=\(message.payload.count)")
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didPublishAck", "Publish ACK received. id=\(id)")
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "didReceiveMessage",
                      "Message received. id=\(id) topic=\(message.topic) payloadLen=\(message.payload.count)")
            currentAppState.setReceivedMessage(text: message.string ?? "")
        }
    }

    nonisolated func mqttDidPing(_ mqtt: CocoaMQTT) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "mqttDidPing", "PING sent")
        }
    }

    nonisolated func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        Task { @MainActor in
            guard mqtt === mqttClient else { return }
            Log.debug(page: LG.page, fn: "mqttDidReceivePong", "PONG received")
        }
    }

    nonisolated func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        Task { @MainActor in
            handleDisconnect(mqtt, error: err)
        }
    }

    // MARK: - TLS handling (DIRECT ONLY, when user explicitly enables it)

    nonisolated func mqtt(_ mqtt: CocoaMQTT,
                          didReceive trust: SecTrust,
                          completionHandler: @escaping (Bool) -> Void) {

        let plan = planSnapshot

        // Never bypass Cloudflare TLS validation.
        if plan.mode == .direct, plan.allowInsecureTLS {
            completionHandler(true)
            return
        }

        if #available(iOS 13.0, *) {
            var error: CFError?
            let ok = SecTrustEvaluateWithError(trust, &error)
            completionHandler(ok)
        } else {
            completionHandler(false)
        }
    }

    nonisolated func mqtt(_ mqtt: CocoaMQTT,
                          didReceive challenge: URLAuthenticationChallenge,
                          completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        let plan = planSnapshot

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Only allow bypass for DIRECT mode when user explicitly enables it.
        if plan.mode == .direct, plan.allowInsecureTLS {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}



////
////  MQTTManager.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/1/24.
////
//
//import Foundation
//import CocoaMQTT
//import Combine
//import SwiftUI
//import Security
//import CryptoKit
//
//@MainActor
//final class MQTTManager: ObservableObject {
//
//    // MARK: - Singleton
//
//    private static let _shared = MQTTManager()
//    class func shared() -> MQTTManager { _shared }
//
//    // MARK: - Logging
//
//    private enum LG {
//        static let page = "MQTTManager"
//    }
//
//    // MARK: - Types
//
//    enum ConnectionState: String {
//        case disconnected
//        case connecting
//        case connected
//    }
//
//    enum MQTTMode: String {
//        case direct
//        case cloudflare
//    }
//
//    // MARK: - Keys
//
//    private enum Keys {
//        static let mqttIsAnonUser         = "mqttIsAnonUser"
//        static let mqttIPAddress          = "mqttIPAddress"
//        static let mqttPortAddress        = "mqttPortAddress"
//        static let mqttUser               = "mqttUser"
//        static let mqttPassword           = "mqttPassword"
//        static let mqttTopic              = "mqttTopic"
//
//        static let mqttUseWebSockets      = "mqttUseWebSockets"
//        static let mqttWebSocketPath      = "mqttWebSocketPath"
//        static let mqttWebSocketUseTLS    = "mqttWebSocketUseTLS"
//
//        static let mqttUseCloudflareMQTT  = "mqttUseCloudflareMQTT"
//
//        // Cloudflare Access creds (CANONICAL — MUST match ViewAuthCloudFlare + AuthCloudFlare)
//        static let cloudFlareClientId     = "cloudFlareClientId"
//        static let cloudFlareClientSecret = "cloudFlareClientSecret"
//
//        // Legacy (migration only)
//        static let legacyCloudFlareSecret = "cloudFlareSecret"
//    }
//
//    private let appGroupSuite = "group.com.viewu.app"
//
//    // MARK: - MQTT
//
//    private func secretFingerprint(_ secret: String) -> String {
//        guard !secret.isEmpty else { return "missing" }
//        let digest = SHA256.hash(data: Data(secret.utf8))
//        return digest.map { String(format: "%02x", $0) }.joined().prefix(12) + ""
//    }
//
//    private var mqttClient: CocoaMQTT?
//    private var pendingMode: MQTTMode = .direct
//
//    // MARK: - State (UI)
//
//    @Published private(set) var connectionState: ConnectionState = .disconnected
//    @Published private(set) var activeMode: MQTTMode = .direct
//
//    // Keep your existing app-state object (your UI references this)
//    let currentAppState = MQTTAppState()
//
//    // MARK: - User-editable settings (persisted)
//
//    @Published var isAnonymous: Bool {
//        didSet { UserDefaults.standard.set(isAnonymous, forKey: Keys.mqttIsAnonUser) }
//    }
//
//    @Published var ip: String {
//        didSet { UserDefaults.standard.set(ip, forKey: Keys.mqttIPAddress) }
//    }
//
//    @Published var port: String {
//        didSet { UserDefaults.standard.set(port, forKey: Keys.mqttPortAddress) }
//    }
//
//    @Published var user: String {
//        didSet { UserDefaults.standard.set(user, forKey: Keys.mqttUser) }
//    }
//
//    @Published var password: String {
//        didSet { UserDefaults.standard.set(password, forKey: Keys.mqttPassword) }
//    }
//
//    @Published var topic: String {
//        didSet { UserDefaults.standard.set(topic, forKey: Keys.mqttTopic) }
//    }
//
//    @Published var useWebSockets: Bool {
//        didSet { UserDefaults.standard.set(useWebSockets, forKey: Keys.mqttUseWebSockets) }
//    }
//
//    @Published var webSocketPath: String {
//        didSet { UserDefaults.standard.set(webSocketPath, forKey: Keys.mqttWebSocketPath) }
//    }
//
//    @Published var webSocketUseTLS: Bool {
//        didSet { UserDefaults.standard.set(webSocketUseTLS, forKey: Keys.mqttWebSocketUseTLS) }
//    }
//
//    /// Settings toggle controls the selected/desired mode.
//    /// Do NOT auto-reconnect here; call `applySettingsAndReconnect()` from Save.
//    @Published var useCloudflareMQTT: Bool {
//        didSet { UserDefaults.standard.set(useCloudflareMQTT, forKey: Keys.mqttUseCloudflareMQTT) }
//    }
//
//    // MARK: - Init
//
//    private init() {
//        let ud = UserDefaults.standard
//
//        self.isAnonymous = ud.bool(forKey: Keys.mqttIsAnonUser)
//        self.ip = ud.string(forKey: Keys.mqttIPAddress) ?? "127.0.0.1"
//        self.port = ud.string(forKey: Keys.mqttPortAddress) ?? "1883"
//        self.user = ud.string(forKey: Keys.mqttUser) ?? ""
//        self.password = ud.string(forKey: Keys.mqttPassword) ?? ""
//        self.topic = ud.string(forKey: Keys.mqttTopic) ?? "viewu/pairing"
//
//        self.useWebSockets = ud.object(forKey: Keys.mqttUseWebSockets) as? Bool ?? true
//        self.webSocketPath = ud.string(forKey: Keys.mqttWebSocketPath) ?? "/mqtt"
//        self.webSocketUseTLS = ud.object(forKey: Keys.mqttWebSocketUseTLS) as? Bool ?? true
//
//        self.useCloudflareMQTT = ud.bool(forKey: Keys.mqttUseCloudflareMQTT)
//
//        self.pendingMode = useCloudflareMQTT ? .cloudflare : .direct
//        self.activeMode = .direct
//    }
//
//    // MARK: - Compatibility setters (used by your Settings view)
//
//    func setAnonymous(anonymous: Bool) { isAnonymous = anonymous }
//    func setIP(ip: String) { self.ip = ip }
//    func setPort(port: String) { self.port = port }
//    func setCredentials(user: String, password: String) {
//        self.user = user
//        self.password = password
//    }
//
//    func setUseCloudflareMQTT(_ enabled: Bool) {
//        useCloudflareMQTT = enabled
//        Log.debug(page: LG.page, fn: "setUseCloudflareMQTT", "useCloudflareMQTT set to \(enabled)")
//    }
//
//    // MARK: - Public API
//
//    func isConnected() -> Bool {
//        connectionState == .connected
//    }
//
//    /// Call from "Save Connection"
//    func applySettingsAndReconnect() {
//        initializeMQTT()
//        connect()
//    }
//
//    // MARK: - Connection lifecycle
//
//    func initializeMQTT() {
//        Log.debug(page: LG.page, fn: "initializeMQTT",
//                  "Starting MQTT init. current client exists=\(mqttClient != nil)")
//
//        // Tear down any existing client cleanly
//        if let existing = mqttClient {
//            Log.debug(page: LG.page, fn: "initializeMQTT", "Disconnecting previous MQTT client")
//            existing.disconnect()
//            mqttClient = nil
//        }
//
//        // Normalize inputs
//        let host = normalizeHost(ip)
//        let portValue = parsePort(port)
//        let path = normalizeWebSocketPath(webSocketPath)
//
//        // Track what mode we intend to use
//        pendingMode = useCloudflareMQTT ? .cloudflare : .direct
//
//        // Read + SYNC Cloudflare Access creds (canonical names; same logic as AuthCloudFlare)
////        let cf = readCloudflareCredsFromAppGroup()
////        let cfId = cf.clientId.trimmingCharacters(in: .whitespacesAndNewlines)
////        let cfSecret = cf.clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
//        let cf = CloudflareAccessCreds.getAndSync()
//        let cfId = cf.clientId
//        let cfSecret = cf.clientSecret
//
//        let cfSecretFP = secretFingerprint(cfSecret)
//
//        let clientID = makeClientId()
//
//        Log.debug(
//            page: LG.page,
//            fn: "initializeMQTT",
//            """
//            Settings snapshot:
//              ip(raw)=\(ip)
//              host(normalized)=\(host)
//              port(raw)=\(port)
//              port(parsed)=\(portValue)
//              useWebSockets=\(useWebSockets)
//              webSocketPath(raw)=\(webSocketPath)
//              webSocketPath(normalized)=\(path)
//              webSocketUseTLS=\(webSocketUseTLS)
//              isAnonymous=\(isAnonymous)
//              useCloudflareMQTT=\(useCloudflareMQTT)
//              cfId=\(redact(cfId)) (\(cfId.count) chars) source=appGroup(\(appGroupSuite)):key=\(Keys.cloudFlareClientId) len=\(cfId.count)
//              cfSecret=\(redact(cfSecret)) (\(cfSecret.count) chars) source=appGroup(\(appGroupSuite)):key=\(Keys.cloudFlareClientSecret) len=\(cfSecret.count)
//              cfSecretFP=\(cfSecretFP)
//              clientID=\(clientID)
//            """
//        )
//
//        // Build client (WebSockets vs direct TCP)
//        let client: CocoaMQTT
//
//        if useWebSockets {
//            let scheme = webSocketUseTLS ? "wss" : "ws"
//            let fullWSURL = "\(scheme)://\(host):\(portValue)\(path)"
//            Log.debug(page: LG.page, fn: "initializeMQTT",
//                      "Configuring MQTT over WebSockets. url=\(fullWSURL)")
//
//            var headers: [String: String] = [
//                "Sec-WebSocket-Protocol": "mqtt"
//            ]
//
//            if useCloudflareMQTT {
//                if cfId.isEmpty || cfSecret.isEmpty {
//                    Log.debug(page: LG.page, fn: "initializeMQTT",
//                              "WARNING: Cloudflare MQTT enabled but CF creds missing. idLen=\(cfId.count) secretLen=\(cfSecret.count)")
//                }
//                if !cfId.isEmpty { headers["CF-Access-Client-Id"] = cfId }
//                if !cfSecret.isEmpty { headers["CF-Access-Client-Secret"] = cfSecret }
//            }
//
//            Log.debug(page: LG.page, fn: "initializeMQTT",
//                      "WebSocket headers: \(describeHeaders(headers))")
//
//            // CocoaMQTTWebSocket expects a URI/path string (e.g. "/mqtt")
//            let ws = CocoaMQTTWebSocket(uri: path)
//            ws.enableSSL = webSocketUseTLS
//            ws.headers = headers
//
//            client = CocoaMQTT(clientID: clientID, host: host, port: portValue, socket: ws)
//
//            if let url = URL(string: fullWSURL) {
//                wssProbe(url: url, headers: headers)
//            }
//        } else {
//            Log.debug(page: LG.page, fn: "initializeMQTT",
//                      "Configuring MQTT over direct TCP. host=\(host) port=\(portValue)")
//            client = CocoaMQTT(clientID: clientID, host: host, port: portValue)
//        }
//
//        // Common client configuration
//        client.keepAlive = 60
//        client.cleanSession = true
//        client.autoReconnect = true
//        client.autoReconnectTimeInterval = 2
//
//        // Username/password only when not anonymous
//        if !isAnonymous {
//            let u = user.trimmingCharacters(in: .whitespacesAndNewlines)
//            let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
//            if !u.isEmpty { client.username = u }
//            if !p.isEmpty { client.password = p }
//        } else {
//            client.username = nil
//            client.password = nil
//        }
//
//        client.delegate = self
//        mqttClient = client
//
//        Log.debug(page: LG.page, fn: "initializeMQTT", "Calling connect()")
//        _ = client.connect()
//    }
//
//    func connect() {
//        guard let client = mqttClient else {
//            Log.error(page: LG.page, fn: "connect", "connect called but mqttClient is nil")
//            return
//        }
//
//        connectionState = .connecting
//        currentAppState.setAppConnectionState(state: .connecting)
//
//        Log.debug(page: LG.page, fn: "connect",
//                  "Attempting connect. host=\(client.host) port=\(client.port) clientID=\(client.clientID)")
//        let ok = client.connect()
//        Log.debug(page: LG.page, fn: "connect", "client.connect() returned \(ok)")
//    }
//
//    func disconnect() {
//        mqttClient?.disconnect()
//        connectionState = .disconnected
//        currentAppState.setAppConnectionState(state: .disconnected)
//    }
//
//    // MARK: - Topics
//
//    private let coreTopics: [(String, CocoaMQTTQoS)] = [
//        ("frigate/events", .qos1),
//        ("viewu/pairing", .qos1)
//    ]
//
//    private func subscribeCoreTopics(_ mqtt: CocoaMQTT) {
//        Log.debug(page: LG.page, fn: "subscribeCoreTopics", "Auto-subscribing to core topics")
//        for (t, qos) in coreTopics {
//            mqtt.subscribe(t, qos: qos)
//        }
//    }
//
//    func publish(topic: String, with payload: String) {
//        guard let mqtt = mqttClient else { return }
//        mqtt.publish(topic, withString: payload, qos: .qos1, retained: false)
//    }
//
//    func publish(_ payload: String, to topic: String? = nil) {
//        publish(topic: topic ?? self.topic, with: payload)
//    }
//
//    // MARK: - Cloudflare creds debug helpers
//
//    func debugDumpCloudflareAccessValues() {
//        let appGroup = UserDefaults(suiteName: appGroupSuite)
//        let standard = UserDefaults.standard
//
//        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
//                  "AppGroup available=\(appGroup != nil) suite=\(appGroupSuite)")
//
//        let agId = appGroup?.string(forKey: Keys.cloudFlareClientId) ?? ""
//        let agSecret = appGroup?.string(forKey: Keys.cloudFlareClientSecret) ?? ""
//        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
//                  "AppGroup: cloudFlareClientId=\(redact(agId)) (\(agId.count) chars) len=\(agId.count)")
//        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
//                  "AppGroup: cloudFlareClientSecret=\(redact(agSecret)) (\(agSecret.count) chars) len=\(agSecret.count)")
//
//        let stId = standard.string(forKey: Keys.cloudFlareClientId) ?? ""
//        let stSecret = standard.string(forKey: Keys.cloudFlareClientSecret) ?? ""
//        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
//                  "Standard: cloudFlareClientId=\(redact(stId)) (\(stId.count) chars) len=\(stId.count)")
//        Log.debug(page: LG.page, fn: "debugDumpCloudflareAccessValues",
//                  "Standard: cloudFlareClientSecret=\(stSecret.isEmpty ? "missing" : redact(stSecret)) len=\(stSecret.count)")
//    }
//
//    // MARK: - Private helpers
//
//    /// Canonical keys:
//    /// - cloudFlareClientId
//    /// - cloudFlareClientSecret
//    ///
//    /// Sync rules (matches AuthCloudFlare / ViewAuthCloudFlare intent):
//    /// - Prefer APP GROUP when it has BOTH id+secret
//    /// - Else prefer STANDARD when it has BOTH id+secret
//    /// - Else merge partials (never overwrite a non-empty with empty)
//    /// - Migrate legacy `cloudFlareSecret` -> `cloudFlareClientSecret` (STANDARD) if needed
//    /// - After choosing, mirror canonical values into BOTH stores
//    private func readCloudflareCredsFromAppGroup() -> (clientId: String, clientSecret: String) {
//
//        let groupUD = UserDefaults(suiteName: appGroupSuite)
//        let stdUD = UserDefaults.standard
//
//        func trimmed(_ s: String?) -> String {
//            (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
//        }
//
//        // Canonical keys
//        let canonIdKey = Keys.cloudFlareClientId
//        let canonSecretKey = Keys.cloudFlareClientSecret
//
//        // Legacy / typo variants (migration only; we always WRITE canon keys)
//        let idKeysToRead = [
//            canonIdKey,
//            "cloudflareClientId",
//            "cloudflareClientid",
//            "cloudflareClientID",
//            "cloudFlareClientID"
//        ]
//
//        let secretKeysToRead = [
//            canonSecretKey,
//            "cloudflareClientSecret",
//            "cloudflareClientsecret",
//            "clouflareClientSecret" // historical typo
//        ]
//
//        func firstNonEmpty(_ ud: UserDefaults?, _ keys: [String]) -> String {
//            guard let ud else { return "" }
//            for k in keys {
//                let v = trimmed(ud.string(forKey: k))
//                if !v.isEmpty { return v }
//            }
//            return ""
//        }
//
//        // Read STANDARD
//        let stdId = firstNonEmpty(stdUD, idKeysToRead)
//        var stdSecret = firstNonEmpty(stdUD, secretKeysToRead)
//
//        // Migrate legacy secret -> canonical secret (STANDARD) if needed
//        if stdSecret.isEmpty {
//            let legacy = trimmed(stdUD.string(forKey: Keys.legacyCloudFlareSecret))
//            if !legacy.isEmpty {
//                stdSecret = legacy
//                stdUD.set(stdSecret, forKey: canonSecretKey)
//                Log.debug(page: LG.page, fn: "readCloudflareCredsFromAppGroup",
//                          "Migrated legacy \(Keys.legacyCloudFlareSecret) -> \(canonSecretKey) (standard)")
//            }
//        }
//
//        // Read APP GROUP
//        let agId = firstNonEmpty(groupUD, idKeysToRead)
//        let agSecret = firstNonEmpty(groupUD, secretKeysToRead)
//
//        // Choose source of truth (prefer complete app group; else complete standard; else merge)
//        let chosenId: String
//        let chosenSecret: String
//        let source: String
//
//        if !agId.isEmpty, !agSecret.isEmpty {
//            chosenId = agId
//            chosenSecret = agSecret
//            source = "appGroup"
//        } else if !stdId.isEmpty, !stdSecret.isEmpty {
//            chosenId = stdId
//            chosenSecret = stdSecret
//            source = "standard"
//        } else {
//            // Merge partials without stomping non-empty values
//            chosenId = !agId.isEmpty ? agId : stdId
//            chosenSecret = !agSecret.isEmpty ? agSecret : stdSecret
//            source = "partial/merged"
//        }
//
//        // Mirror into BOTH stores using CANONICAL keys (never overwrite with empty)
//        if !chosenId.isEmpty {
//            stdUD.set(chosenId, forKey: canonIdKey)
//            groupUD?.set(chosenId, forKey: canonIdKey)
//        }
//        if !chosenSecret.isEmpty {
//            stdUD.set(chosenSecret, forKey: canonSecretKey)
//            groupUD?.set(chosenSecret, forKey: canonSecretKey)
//        }
//
//        Log.debug(
//            page: LG.page,
//            fn: "readCloudflareCredsFromAppGroup",
//            "Synced CF creds across stores. source=\(source) std(id=\(stdId.count),sec=\(stdSecret.count)) appGroup(id=\(agId.count),sec=\(agSecret.count)) chosen(id=\(chosenId.count),sec=\(chosenSecret.count))"
//        )
//
//        return (chosenId, chosenSecret)
//    }
//
//    private func normalizeHost(_ raw: String) -> String {
//        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
//        s = s.replacingOccurrences(of: "https://", with: "")
//        s = s.replacingOccurrences(of: "http://", with: "")
//        s = s.replacingOccurrences(of: "wss://", with: "")
//        s = s.replacingOccurrences(of: "ws://", with: "")
//
//        if let slash = s.firstIndex(of: "/") {
//            s = String(s[..<slash])
//        }
//        if let colon = s.firstIndex(of: ":") {
//            s = String(s[..<colon])
//        }
//        return s
//    }
//
//    private func parsePort(_ raw: String) -> UInt16 {
//        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
//        return UInt16(trimmed) ?? 1883
//    }
//
//    private func normalizeWebSocketPath(_ raw: String) -> String {
//        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
//        if s.isEmpty { return "/mqtt" }
//        if !s.hasPrefix("/") { s = "/" + s }
//        return s
//    }
//
//    private func makeClientId() -> String {
//        let uuid = UUID().uuidString
//        let rand = Int.random(in: 10000...99999)
//        return "viewu_\(uuid)_\(rand)"
//    }
//
//    private func redact(_ s: String) -> String {
//        guard s.count > 10 else { return s }
//        return "\(s.prefix(6))…\(s.suffix(6))"
//    }
//
//    private func describeHeaders(_ headers: [String: String]) -> String {
//        headers.keys.sorted().map { key in
//            "\(key)=len(\(headers[key]?.count ?? 0))"
//        }.joined(separator: ", ")
//    }
//
//    private func wssProbe(url: URL, headers: [String: String]) {
//        var request = URLRequest(url: url)
//        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
//
//        Log.debug(page: LG.page, fn: "wssProbe",
//                  "Starting URLSessionWebSocketTask probe. url=\(url.absoluteString) headers={\(describeHeaders(headers))}")
//
//        let task = URLSession(configuration: .ephemeral).webSocketTask(with: request)
//        task.resume()
//
//        task.sendPing { [weak task] error in
//            Task { @MainActor in
//                if let error {
//                    Log.error(page: LG.page, fn: "wssProbe", "Ping failed: \(error)")
//                } else {
//                    Log.debug(page: LG.page, fn: "wssProbe", "Ping succeeded. WSS handshake appears OK.")
//                }
//                task?.cancel(with: .goingAway, reason: nil)
//            }
//        }
//    }
//
//    private func handleDisconnect(_ mqtt: CocoaMQTT, error: Error?) {
//        guard mqtt === mqttClient else { return }
//
//        if let error {
//            Log.error(page: LG.page, fn: "mqttDidDisconnect", "Disconnected with error: \(error)")
//        } else {
//            Log.warning(page: LG.page, fn: "mqttDidDisconnect", "Disconnected (no error provided)")
//        }
//
//        connectionState = .disconnected
//        currentAppState.setAppConnectionState(state: .disconnected)
//    }
//}
//
//// MARK: - CocoaMQTTDelegate
//
//extension MQTTManager: CocoaMQTTDelegate {
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didConnect", "Socket connected. host=\(host) port=\(port)")
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didStateChangeTo", "State changed -> \(state)")
//
//            switch state {
//            case .connected:
//                connectionState = .connected
//            case .connecting:
//                connectionState = .connecting
//            default:
//                connectionState = .disconnected
//            }
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//
//            Log.debug(page: LG.page, fn: "didConnectAck", "ConnAck received: \(ack)")
//
//            if ack == .accept {
//                activeMode = pendingMode
//                connectionState = .connected
//                currentAppState.setAppConnectionState(state: .connected)
//                subscribeCoreTopics(mqtt)
//            } else {
//                connectionState = .disconnected
//                currentAppState.setAppConnectionState(state: .disconnected)
//            }
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didSubscribeTopics", "Subscribed success=\(success) failed=\(failed)")
//            currentAppState.setAppConnectionState(state: .connectedSubscribed)
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didUnsubscribeTopics", "Unsubscribed topics=\(topics)")
//            currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didPublishMessage",
//                      "Published message. id=\(id) topic=\(message.topic) qos=\(message.qos) payloadLen=\(message.payload.count)")
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didPublishAck", "Publish ACK received. id=\(id)")
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "didReceiveMessage",
//                      "Message received. id=\(id) topic=\(message.topic) payloadLen=\(message.payload.count)")
//            currentAppState.setReceivedMessage(text: message.string ?? "")
//        }
//    }
//
//    nonisolated func mqttDidPing(_ mqtt: CocoaMQTT) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "mqttDidPing", "PING sent")
//        }
//    }
//
//    nonisolated func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
//        Task { @MainActor in
//            guard mqtt === mqttClient else { return }
//            Log.debug(page: LG.page, fn: "mqttDidReceivePong", "PONG received")
//        }
//    }
//
//    nonisolated func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
//        Task { @MainActor in
//            handleDisconnect(mqtt, error: err)
//        }
//    }
//
//    nonisolated func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
//        completionHandler(true)
//    }
//}
