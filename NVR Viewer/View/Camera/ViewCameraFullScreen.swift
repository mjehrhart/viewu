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
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
 
    var body: some View {
        
        
        VStack{
            
            ZStack{
                
                LinearGradient(
                    colors: [cBlue.opacity(0.6), .orange.opacity(0.6), cBlue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                //.ignoresSafeArea()
                //.edgesIgnoringSafeArea(.bottom)
                
                Text("Loading: \(urlString)")
                    .rotationEffect( isLandscape ? .degrees(0) : .degrees(90))
                    .labelStyle(VerticalLabelStyle(show: false))
                    .foregroundStyle(menuTextColor)
                    .onRotate { orientation in
                        if orientation.isValidInterfaceOrientation {
                            isLandscape = orientation.isLandscape
                        }
                    }
                
                
                VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                    .rotationEffect( isLandscape ? .degrees(0) : .degrees(90))
                    .aspectRatio(16/9, contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear(){
                        mediaPlayer.audio?.isMuted = false
                        mediaPlayer.play()
                    }
                    .onDisappear(){
                        mediaPlayer.stop()
                    }
                    .overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
                    .onRotate { orientation in
                        if orientation.isValidInterfaceOrientation {
                            isLandscape = orientation.isLandscape
                        }
                    }
                
//                if horizontalSizeClass == .regular && verticalSizeClass == .regular {
//                    // UI optimized for a regular-sized screen (typical of iPad in most orientations)
//                    VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
//                        .rotationEffect(.degrees(90))
//                        .aspectRatio(16/9, contentMode: .fill)
//                        .frame(width: UIScreen.screenHeight , height: UIScreen.screenWidth )
//                        .edgesIgnoringSafeArea(.all)
//                        .onAppear(){
//                            mediaPlayer.audio?.isMuted = false
//                            mediaPlayer.play()
//                        }
//                        .onDisappear(){
//                            mediaPlayer.stop()
//                        }
//                        .overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
//                } else {
//                    // UI optimized for compact-sized screens (iPhone, or iPad in certain multitasking modes)
//                    VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
//                        //.rotationEffect(.degrees(90))
//                        .aspectRatio(16/9, contentMode: .fit)
//                        .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth + 22)
//                        .edgesIgnoringSafeArea(.all)
//                        .onAppear(){
//                            mediaPlayer.audio?.isMuted = false
//                            mediaPlayer.play()
//                        }
//                        .onDisappear(){
//                            mediaPlayer.stop()
//                        }
//                        .overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
//                }
    
                 
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
                    
                    Spacer()
                    
                    HStack{
                        Button(name){
                            flagMute.toggle()
                            mediaPlayer.audio?.isMuted = flagMute 
                        }
                        .foregroundColor(.white)
                        .font(.title)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 30)
                        .fontWeight(.bold)
                        
                        Button("", systemImage: flagMute ? "speaker.slash" : "speaker"){
                            flagMute.toggle()
                            mediaPlayer.audio?.isMuted = flagMute
                        }
                        .padding([.trailing], 30) //40 was good
                        .padding(.bottom, 30)
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
            //.rotationEffect(.degrees(90))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .navigationDestination(isPresented: $showCameras){
                ViewCamera(title: "Live Cameras")
            }
        }
    }
    
}
 
