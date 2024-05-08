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
        
        media.addOption("-vvvv")
        media.addOptions(
            [
                //"--rtsp-tcp": true,
                "--codec":"avcodec",
                "--avcodec-hw":"none",
                "--avcodec-fast" : true,
                "--avcodec-threads" : "1",
                "network-caching": 500, //300
                "--rtsp-frame-buffer-size":500, //100
                "--vout": "ios",
                "--glconv" : "glconv_cvpx",
                "--rtsp-caching=": 150,
                "--tcp-caching=": 150,
                "--realrtsp-caching=": 150, //150
                //"--h264-fps": 20.0, //20.0
                "--mms-timeout": 60000,
            ]
        )
        
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
            
//            Label("", systemImage: flagMute ? "speaker.slash" : "speaker")
//                .padding(5)
//                .frame(width:UIScreen.screenWidth/2 - 18, alignment: .trailing)
//                .foregroundColor(.white)
//                .onTapGesture{
//                    mediaPlayer.audio.isMuted = flagMute
//                    flagMute.toggle()
//                    print(flagMute, 100);
//                }
            
            Text(name)
                .padding([.top, .trailing], 10)
                .padding(.leading, 10)
                .foregroundColor(.white)
        }
    }
     
}

