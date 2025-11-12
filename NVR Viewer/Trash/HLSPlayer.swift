//
//  HLSPlayer.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/14/24.
//

import Foundation
import MobileVLCKit
import SwiftUI

struct VlcPlayerHLS: UIViewRepresentable{
    func updateUIView(_ uiView: UIView, context: Context) {
     
    }
     
    let urlString: String
//    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VlcPlayerHLS>) {
//    }
    
    func makeUIView(context: Context) -> UIView {
        return PlayerUIViewHLS(frame: .zero, urlString: urlString)
    }
}

class PlayerUIViewHLS: UIView, VLCMediaPlayerDelegate, ObservableObject{
     
    let mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    
    //override
    init(frame: CGRect, urlString: String) {
  
        //super.init(frame: UIScreen.screens[0].bounds)
        super.init(frame: CGRect(x:0,y:0, width:300, height: 250))
         
        let url = URL(string: urlString)!
        let media = VLCMedia(url: url)
        
//        media.addOptions([// Add options here
//            "network-caching": 300,
//            "--rtsp-frame-buffer-size":100,
//            "--vout": "ios",
//            "--glconv" : "glconv_cvpx",
//            "--rtsp-caching=": 150,
//            "--tcp-caching=": 150,
//            "--realrtsp-caching=": 150,
//            "--h264-fps": 20.0,
//            "--mms-timeout": 60000
//                         ])
        
        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self
        mediaPlayer.audio?.isMuted = true
        
        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
        mediaPlayer.play()
    }
    
    func checkConnection() -> Bool{
        let isPlaying: Bool = mediaPlayer.isPlaying
        return isPlaying
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct StreamHLS: View {
    let urlString: String
    var body: some View {
        return VStack{
            VlcPlayerHLS(urlString: urlString)
        }
    }}


