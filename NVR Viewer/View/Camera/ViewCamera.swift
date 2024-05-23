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

class AVRequester: NSObject {
    
    func getStream(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        
    }
}

//struct CameraName: View {
//    
//    let name:String
//  var body: some View {
//    Text(name)
//  }
//}

struct ViewCamera: View {
    
    @ObservedObject var config = NVRConfigurationSuper.shared()
    
    let title: String
    @State var flagFull = false
    //@State private var path = NavigationPath()
    let nvr = NVRConfig.shared()
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    
    @State private var cameraSubStream: Bool = UserDefaults.standard.bool(forKey: "cameraSubStream")
    @State private var cameraRTSPPath: Bool = UserDefaults.standard.bool(forKey: "cameraRTSPPath")
    @State private var camerGo2Rtc: Bool = UserDefaults.standard.bool(forKey: "camerGo2Rtc")
    @State private var cameraHLS: Bool = UserDefaults.standard.bool(forKey: "cameraHLS")
    
    @State var flagAllowNonSub = false
    var counter = 0;
    
    var body: some View {
        ScrollView {
            VStack{
                Section{
                    
                    Section{
                         
                        ForEach(Array(config.item.go2rtc.streams.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, value in
                            
                            if cameraRTSPPath {
                                
                                if cameraSubStream {
                                    if value.contains("sub"){
                                        ForEach(config.item.go2rtc.streams[value]!, id: \.self) { url in
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
                                }else if !value.contains("sub"){
                                    ForEach(config.item.go2rtc.streams[value]!, id: \.self) { url in
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
                        if camerGo2Rtc {
                            
                            VStack{
                               
                                ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, cameraName in
                                    
                                    let camera = config.item.cameras[cameraName];
                                     
                                    //CameraName(name: cameraName)
                                    
                                    ForEach(camera!.ffmpeg.inputs, id: \.self) {item in
                                        
                                        //let url = item.path;
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
                        if cameraHLS {
                            
                            ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, cameraName in
                                
                                let url = nvr.getUrl()
                                Webview(url: url + "/api/\(cameraName)?h=480")
                                    .modifier(CardBackground())
                                    .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
                                    .edgesIgnoringSafeArea(.all)
                                if developerModeIsOn {
                                    Text(url + "/api/\(cameraName)?h=480")
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        
                    }
                }
                Spacer()
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        //.scrollContentBackground(.hidden)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    func verifyGo2RTCUrl(urlString: String) -> String {
        
        let tmp = urlString.split(separator: ":")
        let data = Array(tmp[1])
        let ip = String(data[2...])
        
        if ip == "127.0.0.1" {
            let newAddress = tmp[0] + "://" + nvr.getIP() + ":" + String(tmp[2])
            return newAddress
        }
        
        return urlString
    }
}

struct Webview: UIViewRepresentable {
    
    var url: String
    func makeUIView(context: Context) -> WKWebView {
        
        guard let url = URL(string: self.url) else {
            return WKWebView()
        }
        
        let request = URLRequest(url: url)
        
        let wkWebview = WKWebView()
        wkWebview.load(request)
        return wkWebview
    }
    
    func updateUIView(_ uiView: Webview.UIViewType, context: UIViewRepresentableContext<Webview>) {
    }
}
#Preview {
    ViewCamera(title: "Cameras")
}

//Webview(url: url + "/api/front?h=480")
//    .modifier(CardBackground())
//    .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
//    .edgesIgnoringSafeArea(.all)




