//
//  RTSPPlayer2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/30/24.
//

import Foundation
import MobileVLCKit
import SwiftUI

struct VlcPlayeyRTSP2: UIViewRepresentable{
    
    let urlString: String
    let mediaPlayer : VLCMediaPlayer
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VlcPlayeyRTSP2>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        return PlayerUIView2(frame: .zero, urlString: urlString, mediaPlayer: mediaPlayer)
    }
}

class PlayerUIView2: UIView, VLCMediaPlayerDelegate, ObservableObject{
    
    //override
    init(frame: CGRect, urlString: String, mediaPlayer : VLCMediaPlayer) {
        
        super.init(frame: UIScreen.screens[0].bounds)
        //super.init(frame: CGRect(x:0,y:0, width:350, height: 250))
        
        let url = URL(string: urlString)!
        let media = VLCMedia(url: url)
        
        //https://wiki.videolan.org/VLC_command-line_help
        
        media.addOption("--vv")
        media.addOption("--codec=avcodec")
        media.addOption("--avcodec-hw=any")
        media.addOption("--avcodec-fast=true")
        media.addOption("--avcodec-threads=0")
        media.addOption("--network-caching=300")
        media.addOption("--rtsp-frame-buffer-size=200")
        media.addOption("--vout=ios")
        media.addOption("--glconv=glconv_cvpx")
        media.addOption("--rtsp-caching=150")
        media.addOption("--tcp-caching=150")
        media.addOption("--realrtsp-caching=150")
        media.addOption("--mms-timeout=6000")
        media.addOption("--h264-fps=15.0")
        
        
//        media.addOptions(
//            [
//                //"--rtsp-tcp": true,
//                "codec":"avcodec",
//                "avcodec-hw":"any", // none
//                "avcodec-fast" : true,
//                "avcodec-threads" : 0, // "1" 0=auto
//                "network-caching": 300, //300, 500
//                "rtsp-frame-buffer-size":100, //100, 500
//                "vout": "ios",
//                "glconv" : "glconv_cvpx",
//                "rtsp-caching": 150, //rtsp-caching=
//                "tcp-caching": 150, //tcp-caching=
//                "realrtsp-caching": 150, //150, realrtsp-caching=
//                //"--h264-fps": 20.0, //20.0
//                "mms-timeout": 6000, //60000
//            ]
//        )
        
        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self
        mediaPlayer.audio.isMuted = true
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
        
        //Logging
        //mediaPlayer.libraryInstance.debugLoggingLevel = 1
        //mediaPlayer.libraryInstance.debugLogging = true
        //mediaPlayer.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct StreamRTSP2: View {
    
    let urlString: String
    let cameraName: String
    
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    @State var flagMute = true
    @State var flagFull = false
    
    var body: some View {
        return ZStack{
             
            LinearGradient(
                colors: [.clear, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                .padding(0)
                .aspectRatio(16/9, contentMode: .fit)
                .modifier( CardBackground() )
                .frame(width: UIScreen.screenWidth, height: (UIScreen.screenWidth * 9/16)-5)
                .onAppear(){
                    mediaPlayer.audio.isMuted = flagMute
                    mediaPlayer.play()
                }
                .onDisappear(){
                    mediaPlayer.stop()
                }
                .onTapGesture{
                    flagFull.toggle()
                }
                .overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
             
        }
        .padding(0)
        .navigationDestination(isPresented: $flagFull){
            ViewCameraFullScreen(urlString: urlString, cameraName: cameraName)
        }
    }
    
    struct CameraOverlay: View {
        let name: String
        @State var flagMute = true
        @State var mediaPlayer : VLCMediaPlayer
        
        var body: some View {
             
            Text(name)
                .padding([.top, .trailing], 10)
                .padding(.leading, 10)
                .padding(.bottom, 5)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }
     
}

