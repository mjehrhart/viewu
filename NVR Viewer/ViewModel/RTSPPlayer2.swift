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
        
        
        //super.init(frame: UIScreen.screens[0].bounds)
        super.init(frame: CGRect(x:0,y:0, width:350, height: 250))
        
        let url = URL(string: urlString)!
        let media = VLCMedia(url: url)
        
        // media.addOption("-vv")
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
        
        //
        
        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self
        mediaPlayer.audio.isMuted = true
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
        
        //Logging
        //mediaPlayer.libraryInstance.debugLoggingLevel = 0
        //mediaPlayer.libraryInstance.debugLogging = false 
        //mediaPlayer.play()
    }
  
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
}
 
struct StreamRTSP2: View {
    let urlString: String
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    @State var flagMute = true
    @State var flagFull = false
     
    
    var body: some View {
        return VStack{
             
            HStack{
                Text("value")
                    .frame(width:UIScreen.screenWidth/2 - 18, alignment: .leading)
                    .padding(10)
                
                Label("", systemImage: flagMute ? "speaker.slash" : "speaker")
                    .padding(10)
                    .frame(width:UIScreen.screenWidth/2 - 18, alignment: .trailing)
                    .onTapGesture{
                        flagMute.toggle()
                        mediaPlayer.audio.isMuted = flagMute
                    }
            }
            VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                .aspectRatio(16/9, contentMode: .fit)
                .modifier( CardBackground() )
                .frame(width: UIScreen.screenWidth-20, height: (UIScreen.screenWidth * 9/16)-20 )
//                .frame(width: flagFull ? UIScreen.screenWidth-20 : UIScreen.screenHeight-100,
//                       height: flagFull ? (UIScreen.screenWidth * 9/16)-20 : UIScreen.screenWidth)
                //.edgesIgnoringSafeArea(.all)
                .onAppear(){
                    mediaPlayer.play()
                }
                .onDisappear(){
                    mediaPlayer.stop()
                }
                .onTapGesture{
                    flagFull.toggle()
                    print("clicking onTapGesture")
                    print(flagFull, flagMute)
                    mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
                       
                }
                .navigationDestination(isPresented: $flagFull){
                    ViewCameraFullScreen(urlString: urlString)
                }
        }
    }
}
 
/*
 ["--rtsp-tcp": true, "--codec":"avcodec", "--network-caching":500, "--avcodec-hw":"none"]
 
 "network-caching": 500,
 "sout-rtp-caching": 100,
 "sout-rtp-port-audio": 20000,
 "sout-rtp-port-video": 20002,
 ":rtp-timeout": 10000,
 ":rtsp-tcp": true,
 ":rtsp-frame-buffer-size":1024,
 ":rtsp-caching":0,
 ":live-caching":0,
 
 videoPlayer.media?.addOption(":codec=avcodec")
 videoPlayer.media?.addOption(":vcodec=h264")
 videoPlayer.media?.addOption("--file-caching=2000")
 videoPlayer.media?.addOption("clock-jitter=0")
 videoPlayer.media?.addOption("--rtsp-tcp")
 videoPlayer.media?.clearStoredCookies()
 
 videoPlayer.media?.addOption("-vv")
 
 */
 
