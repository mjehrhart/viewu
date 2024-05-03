//
//  RTSPPlayer.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/14/24.
//
//  https://100.112.116.88:/vod/event/1710363869.504655-fj50kr/master.m3u8
//  rtsp://192.168.1.195:50400/4030f70d4668a1a5/

import Foundation
import MobileVLCKit
import SwiftUI

struct VlcPlayeyRTSP: UIViewRepresentable{
    
    let urlString: String
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VlcPlayeyRTSP>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(frame: .zero, urlString: urlString)
    }
}

class PlayerUIView: UIView, VLCMediaPlayerDelegate, ObservableObject{
    
    let mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    
    //override
    init(frame: CGRect, urlString: String) {
        
        //super.init(frame: UIScreen.screens[0].bounds)
        super.init(frame: CGRect(x:0,y:0, width:150, height: 150))
        
        let url = URL(string: urlString)!
        let media = VLCMedia(url: url)
        
        // media.addOption("-vv")
        media.addOptions(
            [
                //"--rtsp-tcp": true,
                "--codec":"avcodec",
                "--avcodec-hw":"none",
                "--avcodec-fast" : true,
                "--avcodec-threads" : "2",
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
        //mediaPlayer.drawable = self.mediaPlayer
        mediaPlayer.audio.isMuted = true
        
        mediaPlayer.libraryInstance.debugLoggingLevel = 0
        mediaPlayer.libraryInstance.debugLogging = false
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
        mediaPlayer.play()
        
        //1224x662
        
    }
    
    func checkConnection() -> Bool{
        let isPlaying: Bool = mediaPlayer.isPlaying
        return isPlaying
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Below added for debugging - remove if not needed
    //    override func layoutSubviews() {
    //        super.layoutSubviews()
    //      }
}

struct StreamRTSP: View {
    let urlString: String
    
    var body: some View {
        return VStack{
            VlcPlayeyRTSP(urlString: urlString)
        }
    }
}
 
/*
 media.addOptions([// Add options here
 "network-caching": 1000, //300
 "--rtsp-frame-buffer-size":100, //100
 "--vout": "ios",
 "--glconv" : "glconv_cvpx",
 "--rtsp-caching=": 150,
 "--tcp-caching=": 150,
 "--realrtsp-caching=": 150,
 "--h264-fps": 20.0,
 "--mms-timeout": 60000
 ])
 */

/*
 "--network-caching" : "33",
 "--file-caching" : "33",
 "--live-caching" : "33",
 "--clock-synchro" : "0",
 "--clock-jitter" : "0",
 "--h264-fps" : "60",
 "--avcodec-fast" : true,
 "--avcodec-threads" : "1"
 
 */

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

/*
 [
 "--codec" : "avcodec",
 "--avcodec-fast" : true,
 "--avcodec-threads" : "2",
 "network-caching": 1000, //300
 "--rtsp-frame-buffer-size":1000, //100
 "--vout": "ios",
 "--glconv" : "glconv_cvpx",
 "--rtsp-caching=": 150,
 "--tcp-caching=": 150,
 "--realrtsp-caching=": 150, //150
 "--h264-fps": 20.0, //20.0
 "--mms-timeout": 60000
 ]
 */
