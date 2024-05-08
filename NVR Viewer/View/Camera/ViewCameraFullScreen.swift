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
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    
    var body: some View { 
        VStack{
            VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                .rotationEffect(.degrees(90))
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth)
                .edgesIgnoringSafeArea(.all)
                .onAppear(){
                    mediaPlayer.audio.isMuted = falsegi
                    mediaPlayer.play()
                }
                .onDisappear(){
                    mediaPlayer.stop()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.black))
    }
}
 
