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
            
//            LinearGradient(
//                colors: [.clear, .clear],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
            
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
        @State var flagMute = false
        @State var showCameras = false;
        @State var mediaPlayer : VLCMediaPlayer
        
        var body: some View {
            
            //arrow.down.forward.topleading.rectangle
            HStack{
                
                VStack{
                    HStack{
                        Button("", systemImage: "arrow.down.forward.topleading.rectangle"){
                            showCameras.toggle()
                        }
                        .padding([.leading], 85)
                        .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                        .foregroundColor(.white)
                        .font(.title)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 40, alignment: .topLeading)
                    //.background(Color(.yellow))
                    
                    Spacer()
                    
                    HStack{
                        Button(name){
                            flagMute.toggle()
                            mediaPlayer.audio.isMuted = flagMute
                            print("button1")
                        }
                        .foregroundColor(.white)
                        .font(.title)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 10)
                        //.background(Color(.yellow))
                        
                        Button("", systemImage: flagMute ? "speaker.slash" : "speaker"){
                            flagMute.toggle()
                            mediaPlayer.audio.isMuted = flagMute
                        }
                        .padding([.trailing], 80) //40 was good
                        .padding(.bottom, 10)
                        .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                        .foregroundColor(.white)
                        .font(.title)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    //.background(Color(.gray))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                 
            }
            .onTapGesture{
                flagMute.toggle()
                mediaPlayer.audio.isMuted = flagMute
            }
            .background(Color(.init(white: 10, alpha: 0))) 
            .rotationEffect(.degrees(90))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .navigationDestination(isPresented: $showCameras){
                ViewCamera(title: "Live Cameras")
            }
        }
    }
    
}
 
