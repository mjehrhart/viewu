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
    let notify = NotificationHandler()

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
            // format: viewu_device_event_back:<field>:<status>:<value>
            let parts = text.components(separatedBy: ":#:")

            guard parts.count >= 4 else {
                return
            }

            let field = parts[1]
            let status = parts[2]
            let payload = parts[3]

            switch field {
            case "title":
                nts.apnTitle = payload
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.nts.flagTitle = true
                }

            case "domain":
                nts.apnDomain = payload
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.nts.flagDomain = true
                }

            case "template":
                nts.templateString = payload

                let templateParts = payload.split(separator: "::")
                nts.templates.removeAll()

                for template in templateParts {
                    let item = Item(
                        id: UUID(),
                        template: String(template).trimmingCharacters(in: .whitespaces)
                    )
                    nts.templates.append(item)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.nts.flagTemplate = true
                }

            case "paused":
                nts.notificationPaused = Bool(payload) ?? false

            default:
                break
            }

            // Status == "200" triggers alert
            if status == "200" {
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
            Log.shared().print(
                page: "MQTTState",
                fn: "setReceivedMessage",
                type: "ERROR",
                text: "\(error)"
            )
        }
    }

    func setAppConnectionState(state: MQTTAppConnectionState) {
        appConnectionState = state
    }
}


// MARK: - Remove
////
////  MQTTState.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/1/24.
////
//
//import Combine
//import Foundation
//import SwiftData
//import CoreData
//import SwiftUI
//
//final class MQTTAppState: ObservableObject {
// 
//    @StateObject var nts = NotificationTemplateString.shared()
//    let notify = NotificationHandler()
//    @ObservedObject var epsSup = EndpointOptionsSuper.shared()
//    @Published var appConnectionState: MQTTAppConnectionState = .disconnected
//    
//    @Published var historyText: String = ""
//    private var receivedMessage: String = ""
//    
//    @State private var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
//    @AppStorage("viewu_device_paired") private var viewuDevicePaired: Bool = false
//    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
//    
//    func setReceivedMessage(text: String) {
//        DispatchQueue.main.async { [self] in
// 
//        if text.count == 163 {
//            //do nothing as this is a message response back to the viewu server
//            return
//        }
//        else if text.contains("viewu_device_paired"){
//            //device is now paired
//            viewuDevicePaired = true
//            let version = text.components(separatedBy: ":#:") 
//            viewuServerVersion = version[1]
//            nts.alert = true
//            nts.delayText()
//            
//            return
//            
//        } else if text.starts(with: "viewu_device_event_back"){
//            // ie: viewu_device_event_back:title:200:dynamictextgoeshere
//            //print("MQTT MEssage Recieved ------------------------------------------------------")
//            //print(text);
//            
//            let sub = text.split(separator: ":#:")
//             
//            if(sub[1] == "title"){
//                nts.apnTitle = String(sub[3])
//                //Brief purposeful delay in updating the saved icon
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//                    self.nts.flagTitle = true
//                }
//            } else if(sub[1] == "domain"){
//                nts.apnDomain = String(sub[3])
//                //Brief purposeful delay in updating the saved icon
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//                    self.nts.flagDomain = true
//                }
//            } else if(sub[1] == "template"){
//                nts.templateString = String(sub[3])
//                let sub = String(sub[3]).split(separator: "::")
//                nts.templates.removeAll()
//                for template in sub {
//                    let item = Item(id: UUID(), template: String(template).trimmingCharacters(in: .whitespaces))
//                    nts.templates.append(item)
//                }
//                //Brief purposeful delay in updating the saved icon
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//                    self.nts.flagTemplate = true
//                }
//            } else if(sub[1] == "paused"){
//                nts.notificationPaused = Bool(String(sub[3])) ?? false
//            }
//            
//            
//            if(sub[2] == "200") {
//                nts.alert = true
//                nts.delayText()
//            } else {
//                nts.alert = false
//            }
//            
//            return
//            
//        } else if text.starts(with: "viewu_device_event"){
//            //Do nothing as these are from the Viewu app itself
//            return
//        }
//         
//        if developerModeIsOn {
//             
//            do {
//                 
//                let data = text.data(using: .utf8)
//                //let res = try JSONDecoder().decode(TopicFrigateEventHeader.self, from: data!)
//                let res = try JSONDecoder().decode(TopicFrigateEventHeaderMQTT.self, from: data!)
//                  
//                var enteredZones = ""
//                for zone in res.after.entered_zones {
//                    enteredZones += zone! + "|"
//                }
//
//                var currentZones = ""
//                for zone in res.after.entered_zones {
//                    currentZones += zone! + "|"
//                }
//                
//                let before_topic = TopicFrigateEvent(id: res.before.id, camera: res.before.camera, frame_time: res.before.frame_time, label: res.before.label, sub_label: res.before.sub_label, top_score: res.before.top_score, false_positive: res.before.false_positive, start_time: res.before.start_time, end_time: res.before.end_time, score: res.before.score, box: res.before.box, area: res.before.area, ratio: res.before.ratio, region: res.before.region, stationary: res.before.stationary, motionless_count: res.before.motionless_count, position_changes: res.before.position_changes, current_zones: "", entered_zones: "", has_clip: res.before.has_clip)
//                
//                let after_topic = TopicFrigateEvent(id: res.after.id, camera: res.after.camera, frame_time: res.after.frame_time, label: res.after.label, sub_label: res.after.sub_label, top_score: res.after.top_score, false_positive: res.after.false_positive, start_time: res.after.start_time, end_time: res.after.end_time, score: res.after.score, box: res.after.box, area: res.after.area, ratio: res.after.ratio, region: res.after.region, stationary: res.after.stationary, motionless_count: res.after.motionless_count, position_changes: res.after.position_changes, current_zones: currentZones, entered_zones: enteredZones, has_clip: res.after.has_clip)
//                
//                let message = TopicFrigateEventHeader(
//                    before: before_topic,
//                    after: after_topic,
//                    type: res.type
//                )
//                 
//                /******************************/
//                let frigateURLBuilder = APIBuilder(dataSet: message)
//                var eps = frigateURLBuilder.getAllEndpoint()
//                eps.transportType = "mqttState"
// 
//                //Option 3
//                if eps.sublabel == nil {
//                    eps.sublabel = ""
//                }
//                let _: () = EventStorage.shared.insertIfNone(
//                      id: eps.id!,
//                      frameTime: eps.frameTime!,
//                      score: eps.score!,
//                      type: eps.type!,
//                      cameraName: eps.cameraName!,
//                      label: eps.label!,
//                      thumbnail: eps.thumbnail!,
//                      snapshot: eps.snapshot!,
//                      m3u8: eps.m3u8!,
//                      mp4: eps.mp4!,
//                      camera: eps.camera!,
//                      debug: eps.debug!,
//                      image: eps.image!,
//                      transportType: eps.transportType!,
//                      subLabel: eps.sublabel!,  //ADDED 5/26 ?? "" TODO !
//                      currentZones: eps.currentZones!,
//                      enteredZones: eps.enteredZones!
//                )
//                
//                //print("mqttState", id)
//                //TODO: does this need to be here
//                ///-//-//let epsA = EventStorage.shared.readAll() //11/12/25
//                
//                //--------------------------------------------------------------------
//                
//            }
//            catch let error as NSError {  
//                Log.shared().print(page: "MQTTState", fn: "setReceivedMessage", type: "ERROR", text: "\(error)")
//            }
//        }
//        }
//    }
//     
//    func setAppConnectionState(state: MQTTAppConnectionState) {
//        appConnectionState = state
//    }
//}
//
