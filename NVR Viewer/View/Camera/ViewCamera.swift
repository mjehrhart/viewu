//
//  ViewCamera.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation
import SwiftUI
import WebKit
import MobileVLCKit
import TipKit

class AVRequester: NSObject {
    
    func getStream(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        
    }
}


struct ViewCamera: View {
   
   //11/09/25
   //@ObservedObject var config = NVRConfigurationSuper.shared()
   @ObservedObject var config = NVRConfigurationSuper2.shared()
   
   let title: String
   @State var flagFull = false
   let nvr = NVRConfig.shared()
   var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
   
   @State private var cameraSubStream: Bool = UserDefaults.standard.bool(forKey: "cameraSubStream")
   @State private var cameraRTSPPath: Bool = UserDefaults.standard.bool(forKey: "cameraRTSPPath")
   @State private var camerGo2Rtc: Bool = UserDefaults.standard.bool(forKey: "camerGo2Rtc")
   @State private var cameraHLS: Bool = UserDefaults.standard.bool(forKey: "cameraHLS")
   
   @State var flagAllowNonSub = false
   var counter = 0;
   
   var hasHttpsLanHLS: Bool {
       guard cameraHLS else { return false }      // only care if HLS is enabled

       let baseURL = nvr.getUrl()                // e.g. "https://192.168.1.152:8971"
       return isHttpsLanURL(baseURL)
   }
   
   //Use the dismiss action
   @Environment(\.dismiss) var dismiss
    
//    var sortedCameraKeys: Cameras2  {
//        config.item.cameras.keys.sorted { $0.cameraName < $1.cameraName }
//    }
   
   func getCameraKeys() -> [String] {
       let cameraDictionary: [String: Cameras2] = config.item.cameras
       return Array(cameraDictionary.keys)
   }
   
   var body: some View {
       ScrollView {
           VStack(spacing: 12) {

               if !hasHttpsLanHLS {
                   ViewTipsLiveCameras(
                       title: "Live Cameras",
                       message: "You can change the camera stream from the Settings page. To reduce load times, use a sub-stream whenever possible."
                   )
                   .padding(15)
               }

               // 🔔 HLS + LAN + HTTPS warning banner
               if hasHttpsLanHLS {
                   Spacer()
                   HStack(alignment: .top, spacing: 8) {
                       Image(systemName: "exclamationmark.triangle.fill")
                           .font(.system(size: 14, weight: .bold))
                           .foregroundColor(.yellow)

                       VStack(alignment: .leading, spacing: 4) {
                           Text("Streams Will Not Play")
                               .font(.system(size: 13, weight: .semibold))

                           Text("iOS blocks HTTPS streams to IP addresses that use self-signed certificates. If your Frigate server uses a self-signed cert on an IP (for example https://192.168.1.150:8971), HLS video may not display.")
                               .font(.system(size: 11))
                               .foregroundColor(.secondary)
                       }
                   }
                   .padding(10)
                   .background(Color.orange.opacity(0.12))
                   .cornerRadius(12)
                   .padding(.horizontal, 10)
               }
         
                Section{
                    if ( config.item.go2rtc.streams != nil  ){
                        
                        ForEach(Array(config.item.go2rtc.streams!.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, value in
                            
                            if config.item.cameras[value]?.enabled == true {
                                
                                if cameraRTSPPath {
                                    
                                    if cameraSubStream {
                                        if value.contains("sub"){
                                            ForEach(config.item.go2rtc.streams![value]!, id: \.self) { url in
                                                ScrollView(.horizontal){
                                                    
                                                    if url.starts(with: "rtsp"){
                                                        let name = value + "_sub"
                                                        StreamRTSP2(urlString: url, cameraName: name)
                                                            .padding(0)
                                                        if developerModeIsOn {
                                                            Text(url)
                                                                .textSelection(.enabled)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }else if !value.contains("sub"){
                                        ForEach(config.item.go2rtc.streams![value]!, id: \.self) { url in
                                            ScrollView(.horizontal){
                                                
                                                if url.starts(with: "rtsp"){
                                                    StreamRTSP2(urlString: url, cameraName: value)
                                                        .padding(0)
                                                    if developerModeIsOn {
                                                        Text(url)
                                                            .textSelection(.enabled)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if camerGo2Rtc {
                        
                        VStack{
                            
                            ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, cameraName in

                                if config.item.cameras[cameraName]?.enabled == true {
                                    
                                    let camera = config.item.cameras[cameraName];
                                    ForEach(camera!.ffmpeg.inputs, id: \.self) {item in
                                        
                                        let url = verifyGo2RTCUrl(urlString: item.path)
                                        
                                        if cameraSubStream {
                                            if url.contains("sub") || cameraName.contains("sub"){
                                                
                                                if url.starts(with: "rtsp"){
                                                    
                                                    let name = cameraName + "_sub"
                                                    StreamRTSP2(urlString: url, cameraName: name)
                                                        .padding(0)
                                                    if developerModeIsOn {
                                                        Text(url)
                                                            .textSelection(.enabled)
                                                    }
                                                }
                                            }
                                        } else {
                                            if !url.contains("sub"){
                                                
                                                if url.starts(with: "rtsp"){
                                                    StreamRTSP2(urlString: url, cameraName: cameraName)
                                                        .padding(0)
                                                    if developerModeIsOn {
                                                        Text(url)
                                                            .textSelection(.enabled)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if cameraHLS {
                            
                            ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, cameraName in
                                    
                                if config.item.cameras[cameraName]?.enabled == true {
                                    
                                    let url = nvr.getUrl()
                                    HLSPlayer2(urlString: url, cameraName: cameraName, flagFull: false)
                                    if developerModeIsOn {
                                        Text(url + "/api/\(cameraName)?h=480")
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                    }
                }
           
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollIndicators(.hidden)
        .navigationBarBackButtonHidden(true)
        .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss() // Manually dismiss the view
                    }) {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                    }
                }
            }
    }
    
    func verifyGo2RTCUrl(urlString: String) -> String {
        
        let tmp = urlString.split(separator: ":")
        let data = Array(tmp[1])
        let ip = String(data[2...])
        
        if ip == "127.0.0.1" {
            let newAddress = tmp[0] + "://" + nvr.getIP() + ":" + String(tmp[2])
            return newAddress
        }
        
        if ip == "localhost" {
            let newAddress = tmp[0] + "://" + nvr.getIP() + ":" + String(tmp[2])
            return newAddress
        }
        
        return urlString
    }
}


