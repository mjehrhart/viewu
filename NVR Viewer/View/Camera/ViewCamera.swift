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

struct ViewCamera: View {
    
    //
    @ObservedObject var config = NVRConfigurationSuper.shared()
    
    let title: String
    @State private var path = NavigationPath()
    
//    @State var mediaPlayer1 : VLCMediaPlayer = VLCMediaPlayer()
//    @State var mediaPlayer2 : VLCMediaPlayer = VLCMediaPlayer()
//    
//    @State var flagMute1 = true
//    @State var flagMute2 = true
    
    var body: some View {
        ScrollView {
            VStack{
                Section{
                    
                    Section{
                        //HStack{
                        ForEach(Array(config.item.go2rtc.streams.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, value in
                             
                            if value.contains("_sub"){
                                Text(value)
                                ForEach(config.item.go2rtc.streams[value]!, id: \.self) { url in
                                    ScrollView(.horizontal){
                                        
                                        if url.starts(with: "rtsp"){
                                            StreamRTSP2(urlString: url)
                                        }
                                    }
                                }
                            }
                        }
                        //}
                    } header: {
                        Text("Cameras")
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .scrollContentBackground(.hidden)
        .toolbarBackground(.secondary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
 
//Webview(url: "http://100.73.173.67:5555/api/front?h=480")
//    .modifier(CardBackground())
//    .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
//    .edgesIgnoringSafeArea(.all)
//Webview(url: "http://100.73.173.67:5555/api/side?h=480")
//    .modifier(CardBackground())
//    .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
//    .edgesIgnoringSafeArea(.all)




