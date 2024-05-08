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
    let cameraName: String
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
    
    var body: some View { 
        ZStack{
            
            LinearGradient(
                colors: [.clear, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                .rotationEffect(.degrees(90))
                .aspectRatio(16/9, contentMode: .fit)
                .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth)
                .edgesIgnoringSafeArea(.all)
                .onAppear(){
                    mediaPlayer.audio.isMuted = false
                    mediaPlayer.play()
                }
                .onDisappear(){
                    mediaPlayer.stop()
                }
                .overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.black))
    }
    
    struct CameraOverlay: View {
        let name: String
        @State var flagMute = true
        @State var mediaPlayer : VLCMediaPlayer
        
        var body: some View {
            
            HStack{
                
                Text(name)
                    .foregroundColor(.white)
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding([.trailing], 20)
                    .padding(.bottom, 10)
                    //.background(Color(.yellow))
                
                Label("", systemImage: flagMute ? "speaker" : "speaker.slash")
                    .padding([.trailing], 90)
                    .padding(.bottom, 10)
                    //.frame(width:UIScreen.screenWidth/2 - 18, alignment: .trailing)
                    .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                    .foregroundColor(.white)
                    .font(.title)
                    .onTapGesture{
                        mediaPlayer.audio.isMuted = flagMute
                        flagMute.toggle()
                    }
                    .background(Color(.clear))
                     
                 
            }
            .rotationEffect(.degrees(90))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
    
}
 
