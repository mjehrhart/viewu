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
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    let menuTextColor = Color.white
    
    var body: some View {
        
        
        VStack{
            
            ZStack{
                
                LinearGradient(
                    colors: [.orange, cBlue, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                //.ignoresSafeArea()
                //.edgesIgnoringSafeArea(.bottom)
                
                Text("Loading: \(urlString)")
                    .rotationEffect(.degrees(90))
                    .labelStyle(VerticalLabelStyle(show: false))
                    .foregroundStyle(menuTextColor)
                
                VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                    .rotationEffect(.degrees(90))
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth + 22)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear(){
                        mediaPlayer.audio?.isMuted = false
                        mediaPlayer.play()
                    }
                    .onDisappear(){
                        mediaPlayer.stop()
                    }
                    .overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
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
//                    HStack{
//                        Button("", systemImage: "arrow.down.forward.topleading.rectangle"){
//                            showCameras.toggle()
//                        }
//                        .padding([.leading], 85)
//                        .frame(maxHeight: .infinity, alignment: .bottomTrailing)
//                        .foregroundColor(.white)
//                        .font(.title)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: 40, alignment: .topLeading)
                    
                    Spacer()
                    
                    HStack{
                        Button(name){
                            flagMute.toggle()
                            mediaPlayer.audio?.isMuted = flagMute
                            print("button1")
                        }
                        .foregroundColor(.white)
                        .font(.title)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 10)
                        .fontWeight(.bold)
                        
                        Button("", systemImage: flagMute ? "speaker.slash" : "speaker"){
                            flagMute.toggle()
                            mediaPlayer.audio?.isMuted = flagMute
                        }
                        .padding([.trailing], 80) //40 was good
                        .padding(.bottom, 10)
                        .frame(maxHeight: .infinity, alignment: .bottomTrailing)
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                 
            }
            .onTapGesture{
                flagMute.toggle()
                mediaPlayer.audio?.isMuted = flagMute //11/12/25 Check this
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
 
