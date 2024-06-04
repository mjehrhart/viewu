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
 
    let notify = NotificationHandler()
    @ObservedObject var epsSup = EndpointOptionsSuper.shared()
    @Published var appConnectionState: MQTTAppConnectionState = .disconnected
    
    @Published var historyText: String = ""
    private var receivedMessage: String = ""
    
    @State private var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    @AppStorage("viewu_device_paired") private var viewuDevicePaired: Bool = false
    @AppStorage("viewu_server_version") private var viewuServerVersion: String = "0.0.0"
    
    func setReceivedMessage(text: String) {
         
        if text.count == 163 {
            //do nothing as this is a message response back to the viewu server
            return
        }
        else if text.contains("viewu_device_paired"){
            //device is now paired
            viewuDevicePaired = true
            let version = text.components(separatedBy: ":") 
            viewuServerVersion = version[1]
            
            return
        }
         
        if developerModeIsOn {
            
            print("MQTTAppState::setReceivedMessage::developerModeIsOn")
            print(text)
            
            do {
                 
                let data = text.data(using: .utf8)
                
                let res = try JSONDecoder().decode(TopicFrigateEventHeader.self, from: data!)
                 
                let frigateURLBuilder = APIBuilder(dataSet: res)
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
                      subLabel: eps.sublabel!, //ADDED 5/26 ?? "" TODO !
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

