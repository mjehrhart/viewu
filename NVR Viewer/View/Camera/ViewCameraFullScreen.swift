//
//  ViewCameraFullScreen.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/7/24.
//

import Foundation
import MobileVLCKit
import SwiftUI

struct ViewCameraFullScreen: View {
    
    let urlString: String
    @State var flagMute = true
    @State var flag = false
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    
    var body: some View { 
        VStack{
            VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                .rotationEffect(.degrees(90))
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: UIScreen.screenHeight + (UIScreen.screenHeight * 0.05), height: UIScreen.screenWidth + (UIScreen.screenWidth * 0.05))
                .edgesIgnoringSafeArea(.all)
                .onAppear(){
                    mediaPlayer.play()
                }
                .onDisappear(){
                    mediaPlayer.stop()
                }
                .onTapGesture{
                    flag.toggle()
                    mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.black))
    }
}
 
