//
//  MQTTState.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Combine
import Foundation
import SwiftData
import CoreData
import SwiftUI

final class MQTTAppState: ObservableObject {
 
    @StateObject var nts = NotificationTemplateString.shared()
    let notify = NotificationHandler()
    @ObservedObject var epsSup = EndpointOptionsSuper.shared()
    @Published var appConnectionState: MQTTAppConnectionState = .disconnected
    
    @Published var historyText: String = ""
    private var receivedMessage: String = ""
    
    @State private var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    @AppStorage("viewu_device_paired") private var viewuDevicePaired: Bool = false
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
    
    func setReceivedMessage(text: String) {
         
         
//        print("**********************:: setReceivedMessage")
//        print(text)
//        print(text.count)
//        print("___________________________________________")
        
        if text.count == 163 {
            //do nothing as this is a message response back to the viewu server
            return
        }
        else if text.contains("viewu_device_paired"){
            //device is now paired
            viewuDevicePaired = true
            let version = text.components(separatedBy: ":") 
            viewuServerVersion = version[1]
            nts.alert = true
            nts.delayText()
            
            return
            
        } else if text.starts(with: "viewu_device_event_back"){
            // viewu_device_event_back:title:200
            print(text);
            
            let sub = text.split(separator: ":")
            
            if(sub[1] == "title"){
                nts.flagTitle = true
            } else if(sub[1] == "domain"){
                nts.flagDomain = true
            } else if(sub[1] == "template"){
                nts.flagTemplate = true
            } else if(sub[1] == "paused"){
                
            } else if(sub[1] == "time_paused"){
                
            }
            
            
            if(sub[2] == "200") {
                nts.alert = true
                nts.delayText()
            } else {
                nts.alert = false
            }
            
            return
        } else if text.starts(with: "viewu_device_event"){
             
            //Do nothing as these are from the Viewu app itself
            return
        }
         
        if developerModeIsOn {
             
            do {
                 
                let data = text.data(using: .utf8)
                //let res = try JSONDecoder().decode(TopicFrigateEventHeader.self, from: data!)
                
                /******************************/
                let res = try JSONDecoder().decode(TopicFrigateEventHeaderMQTT.self, from: data!)
                  
                var enteredZones = ""
                for zone in res.after.entered_zones {
                    enteredZones += zone! + "|"
                }

                var currentZones = ""
                for zone in res.after.entered_zones {
                    currentZones += zone! + "|"
                }
                
                let before_topic = TopicFrigateEvent(id: res.before.id, camera: res.before.camera, frame_time: res.before.frame_time, label: res.before.label, sub_label: res.before.sub_label, top_score: res.before.top_score, false_positive: res.before.false_positive, start_time: res.before.start_time, end_time: res.before.end_time, score: res.before.score, box: res.before.box, area: res.before.area, ratio: res.before.ratio, region: res.before.region, stationary: res.before.stationary, motionless_count: res.before.motionless_count, position_changes: res.before.position_changes, current_zones: "", entered_zones: "", has_clip: res.before.has_clip)
                
                let after_topic = TopicFrigateEvent(id: res.after.id, camera: res.after.camera, frame_time: res.after.frame_time, label: res.after.label, sub_label: res.after.sub_label, top_score: res.after.top_score, false_positive: res.after.false_positive, start_time: res.after.start_time, end_time: res.after.end_time, score: res.after.score, box: res.after.box, area: res.after.area, ratio: res.after.ratio, region: res.after.region, stationary: res.after.stationary, motionless_count: res.after.motionless_count, position_changes: res.after.position_changes, current_zones: currentZones, entered_zones: enteredZones, has_clip: res.after.has_clip)
                
                let message = TopicFrigateEventHeader(
                    before: before_topic,
                    after: after_topic,
                    type: res.type
                )
                 
                /******************************/
                let frigateURLBuilder = APIBuilder(dataSet: message)
                var eps = frigateURLBuilder.getAllEndpoint()
                eps.transportType = "mqttState"
                 
                
                //            var eps2 = EndpointOptionsSuper.EventMeta()
                //            eps2.id = eps.id
                //            eps2.camera = eps.camera
                //            eps2.cameraName = eps.cameraName
                //            eps2.debug = eps.debug
                //            eps2.frameTime = eps.frameTime
                //            eps2.image = eps.image
                //            eps2.label = eps.label
                //            eps2.m3u8 = eps.m3u8
                //            eps2.score = eps.score
                //            eps2.snapshot = eps.snapshot
                //            eps2.thumbnail = eps.thumbnail
                //            eps2.transportType = eps.transportType
                //            eps2.type = eps.type
                
                
                //------------------>
                //epsSup.list2.insert(eps2, at: 0)
                //            if epsSup.list2.contains(where: {$0.frameTime == eps2.frameTime}) {
                //               // do nothing
                //                print("epsSup.list2.contains where framTime == ", eps2.frameTime)
                //            } else {
                //                epsSup.list2.insert(eps2, at: 0)
                //                print("epsSup.list2.insert at 0 framTime == ", eps2.frameTime)
                //            }
                //------------------>
  
                //Option 3 
                if eps.sublabel == nil {
                    eps.sublabel = ""
                }
                let id = EventStorage.shared.insertIfNone(
                      id: eps.id!,
                      frameTime: eps.frameTime!,
                      score: eps.score!,
                      type: eps.type!,
                      cameraName: eps.cameraName!,
                      label: eps.label!,
                      thumbnail: eps.thumbnail!,
                      snapshot: eps.snapshot!,
                      m3u8: eps.m3u8!,
                      camera: eps.camera!,
                      debug: eps.debug!,
                      image: eps.image!,
                      transportType: eps.transportType!,
                      subLabel: eps.sublabel!,  //ADDED 5/26 ?? "" TODO !
                      currentZones: eps.currentZones!,
                      enteredZones: eps.enteredZones!
                )
                
                print("mqttState", id)
                //TODO: does this need to be here
                let epsA = EventStorage.shared.readAll()
                
                //--------------------------------------------------------------------
                
            }
            catch let error as NSError { 
                print(error)
                Log.shared().print(page: "MQTTState", fn: "setReceivedMessage", type: "ERROR", text: "\(error)")
            }
        } 
    }
     
    func setAppConnectionState(state: MQTTAppConnectionState) {
        appConnectionState = state
    }
}

