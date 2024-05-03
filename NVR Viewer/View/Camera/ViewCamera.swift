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
    
    let title: String
    @State private var path = NavigationPath()
    
    @State var mediaPlayer1 : VLCMediaPlayer = VLCMediaPlayer()
    @State var mediaPlayer2 : VLCMediaPlayer = VLCMediaPlayer()
    
    @State var flagMute1 = true
    @State var flagMute2 = true
    
    var body: some View {
        ScrollView {
            VStack{
                Section{
                    HStack{
                        Text("Camera Front")
                            .frame(width:UIScreen.screenWidth/2 - 18, alignment: .leading)
                            .padding(10)
                        
                        Label("", systemImage: flagMute1 ? "speaker.slash" : "speaker")
                            .padding(10)
                            .frame(width:UIScreen.screenWidth/2 - 18, alignment: .trailing)
                            .onTapGesture{
                                flagMute1.toggle()
                                mediaPlayer1.audio.isMuted = flagMute1
                            }
                    }
                    //.background(.blue, in: RoundedRectangle(cornerRadius: 5) )
                      
                    StreamRTSP2(urlString: "rtsp://100.116.231.89:50400/70d3ddca11611ee9", mediaPlayer: mediaPlayer1)
                        .modifier(CardBackground())
                        .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear(){
                            mediaPlayer1.play()
                        }
                        .onDisappear(){
                            mediaPlayer1.stop()
                        }
                }
                
                Section{
                    HStack{
                        Text("Camera Side")
                            .frame(width:UIScreen.screenWidth/2 - 18, alignment: .leading)
                            .padding(10)
                        
                        Label("", systemImage: flagMute2 ? "speaker.slash" : "speaker")
                            .padding(10)
                            .frame(width:UIScreen.screenWidth/2 - 18, alignment: .trailing)
                            .onTapGesture{
                                flagMute2.toggle()
                                mediaPlayer2.audio.isMuted = flagMute2
                            }
                    }
                    //.background(.blue, in: RoundedRectangle(cornerRadius: 5) )
                    
                    StreamRTSP2(urlString: "rtsp://100.116.231.89:50573/d9654200d47c7808", mediaPlayer: mediaPlayer2)
                        .modifier(CardBackground())
                        .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear(){
                            mediaPlayer2.play()
                        }
                        .onDisappear(){
                            mediaPlayer2.stop()
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

/*
 Front
 rtsp://192.168.1.195:50400/70d3ddca11611ee9 //sub 70d3ddca11611ee9, //main 4030f70d4668a1a5
 rtsp://admin:m12345678@192.168.1.187:554/cam/realmonitor?channel=1&subtype=1
 
 Side
 rtsp://192.168.1.195:50573/d9654200d47c7808 //main 615f8839cbee0e5c, //sub d9654200d47c7808
 rtsp://admin:m12345678@192.168.1.186:554/cam/realmonitor?channel=1&subtype=1
 */

//Webview(url: "http://100.73.173.67:5555/api/front?h=480")
//    .modifier(CardBackground())
//    .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
//    .edgesIgnoringSafeArea(.all)
//Webview(url: "http://100.73.173.67:5555/api/side?h=480")
//    .modifier(CardBackground())
//    .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20)
//    .edgesIgnoringSafeArea(.all)




