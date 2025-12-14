//
//  MQTTState.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Combine
import Foundation

@MainActor
final class MQTTAppState: ObservableObject {

    // MARK: - Dependencies / shared state

    /// Template strings & flags for notifications
    let nts = NotificationTemplateString.shared()

    /// Endpoint options manager (not currently used here, but kept)
    let epsSup = EndpointOptionsSuper.shared()

    /// Optional notification handler (currently unused)
    //let notify = NotificationHandler()

    // MARK: - Connection state

    @Published var appConnectionState: MQTTAppConnectionState = .disconnected

    @Published var historyText: String = ""
    private var receivedMessage: String = ""

    // MARK: - Flags / persisted settings

    private let developerModeIsOn: Bool =
        UserDefaults.standard.bool(forKey: "developerModeIsOn")

    private var viewuDevicePaired: Bool {
        get { UserDefaults.standard.bool(forKey: "viewu_device_paired") }
        set { UserDefaults.standard.set(newValue, forKey: "viewu_device_paired") }
    }

    private var viewuServerVersion: String {
        get { UserDefaults.standard.string(forKey: "viewu_server_version") ?? "0.0.0" }
        set { UserDefaults.standard.set(newValue, forKey: "viewu_server_version") }
    }

    // MARK: - Public API

    func setReceivedMessage(text: String) {

        print("[MJE] Received message: \(text)")
        // Ignore this specific "response" message (magic length 163)
        if text.count == 163 {
            return
        }

        // Device paired message
        if text.contains("viewu_device_paired") {
            // format: "viewu_device_paired:...:#:version"
            let parts = text.components(separatedBy: ":#:")
            if parts.count > 1 {
                viewuDevicePaired = true
                viewuServerVersion = parts[1]
            } else {
                viewuDevicePaired = true
            }

            nts.alert = true
            nts.delayText()
            return
        }

        // Device event callback from server
        if text.starts(with: "viewu_device_event_back") {
            let parts = text.components(separatedBy: ":#:")
            guard parts.count >= 4 else { return }

            let field = parts[1]
            let status = parts[2]
            let payload = parts[3]
            let ok = (status == "200")

            switch field {
            case "title":
                nts.apnTitle = payload
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.nts.flagTitle = ok
                }

            case "domain":
                nts.apnDomain = payload
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.nts.flagDomain = ok
                }

            case "template":
                nts.templateString = payload

                // Your current split looks suspicious (split(separator: "::") doesn't compile in Swift).
                // Prefer:
                let templateParts = payload.components(separatedBy: "::")
                nts.templates.removeAll()
                for template in templateParts {
                    nts.templates.append(Item(id: UUID(),
                                              template: template.trimmingCharacters(in: .whitespaces)))
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.nts.flagTemplate = ok
                }

            case "paused":
                nts.notificationPaused = (payload == "true" || payload == "1")

            default:
                break
            }

            if ok {
                nts.alert = true
                nts.delayText()
            } else {
                nts.alert = false
            }
            return
        }


        // Events originating from this app – ignore
        if text.starts(with: "viewu_device_event") {
            return
        }

        // Developer mode: decode raw Frigate MQTT event JSON and persist as EndpointOptions
        guard developerModeIsOn else {
            return
        }

        do {
            guard let data = text.data(using: .utf8) else { return }

            // MQTT-specific header type
            let res = try JSONDecoder().decode(TopicFrigateEventHeaderMQTT.self, from: data)

            // Build zone strings safely
            let enteredZones = res.after.entered_zones
                .compactMap { $0 }
                .joined(separator: "|")

            let currentZones = res.after.current_zones
                .compactMap { $0 }
                .joined(separator: "|")

            // Construct the before / after topic events
            let before_topic = TopicFrigateEvent(
                id: res.before.id,
                camera: res.before.camera,
                frame_time: res.before.frame_time,
                label: res.before.label,
                sub_label: res.before.sub_label,
                top_score: res.before.top_score,
                false_positive: res.before.false_positive,
                start_time: res.before.start_time,
                end_time: res.before.end_time,
                score: res.before.score,
                box: res.before.box,
                area: res.before.area,
                ratio: res.before.ratio,
                region: res.before.region,
                stationary: res.before.stationary,
                motionless_count: res.before.motionless_count,
                position_changes: res.before.position_changes,
                current_zones: "",
                entered_zones: "",
                has_clip: res.before.has_clip
            )

            let after_topic = TopicFrigateEvent(
                id: res.after.id,
                camera: res.after.camera,
                frame_time: res.after.frame_time,
                label: res.after.label,
                sub_label: res.after.sub_label,
                top_score: res.after.top_score,
                false_positive: res.after.false_positive,
                start_time: res.after.start_time,
                end_time: res.after.end_time,
                score: res.after.score,
                box: res.after.box,
                area: res.after.area,
                ratio: res.after.ratio,
                region: res.after.region,
                stationary: res.after.stationary,
                motionless_count: res.after.motionless_count,
                position_changes: res.after.position_changes,
                current_zones: currentZones,
                entered_zones: enteredZones,
                has_clip: res.after.has_clip
            )

            let message = TopicFrigateEventHeader(
                before: before_topic,
                after: after_topic,
                type: res.type
            )

            // Build endpoints and persist
            let frigateURLBuilder = APIBuilder(dataSet: message)
            var eps = frigateURLBuilder.getAllEndpoint()
            eps.transportType = "mqttState"

            if eps.sublabel == nil {
                eps.sublabel = ""
            }

            _ = EventStorage.shared.insertIfNone(
                id: eps.id!,
                frameTime: eps.frameTime!,
                score: eps.score!,
                type: eps.type!,
                cameraName: eps.cameraName!,
                label: eps.label!,
                thumbnail: eps.thumbnail!,
                snapshot: eps.snapshot!,
                m3u8: eps.m3u8!,
                mp4: eps.mp4!,
                camera: eps.camera!,
                debug: eps.debug!,
                image: eps.image!,
                transportType: eps.transportType!,
                subLabel: eps.sublabel!,
                currentZones: eps.currentZones!,
                enteredZones: eps.enteredZones!
            )

        } catch {
            Log.error(
                page: "MQTTState",
                fn: "setReceivedMessage", "\(error)"
            )
        }
    }

    func setAppConnectionState(state: MQTTAppConnectionState) {
        appConnectionState = state
    }
}
