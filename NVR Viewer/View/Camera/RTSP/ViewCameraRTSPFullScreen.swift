//
//  ViewCameraFullScreen.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/7/24.
//
 
import SwiftUI
import MobileVLCKit
 
@MainActor
struct ViewCameraRTSPFullScreen: View {
    
    let urlString: String 
    let cameraName: String
    
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    let menuTextColor = Color.white
    
    //@State var orientation = UIDevice.current.orientation
    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
    }
    
        struct CameraOverlay: View {
            let name: String
            let mediaPlayer: VLCMediaPlayer
    
            @State private var isMuted = false
    
            private func toggleMute() {
                isMuted.toggle()
                mediaPlayer.audio?.isMuted = isMuted
            }
    
            var body: some View {
                VStack {
                    Spacer()
    
                    HStack {
                        Button(action: toggleMute) {
                            Text(name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .bottomLeading)
                        .padding(.bottom, 30)
    
                        Button(action: toggleMute) {
                            Image(systemName: isMuted ? "speaker.slash" : "speaker")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleMute()
                }
            }
        }
}
 
 
//@MainActor
//struct ViewCameraRTSPFullScreen: View {
//
//    let urlString: String
//    let cameraName: String
//
//    // Single shared player instance for this screen
//    let mediaPlayer = VLCMediaPlayer()
//
//    private let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
//    private let menuTextColor = Color.white
//
//    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
//
//    // Rotation angle: keep video “landscape” even when device is portrait
//    private var rotationAngle: Angle {
//        isLandscape ? .degrees(0) : .degrees(90)
//    }
//
//    var body: some View {
//        VStack {
//            ZStack {
//                // Background gradient
//                LinearGradient(
//                    colors: [cBlue.opacity(0.6), .orange.opacity(0.6), cBlue.opacity(0.6)],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .ignoresSafeArea()
//
//                // Loading text overlay
//                Text("Loading: \(urlString)")
//                    .rotationEffect(rotationAngle)
//                    .foregroundStyle(menuTextColor)
//
//                // RTSP player
//                VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
//                    .rotationEffect(rotationAngle)
//                    .aspectRatio(16/9, contentMode: .fill)
//                    .edgesIgnoringSafeArea(.all)
//                    .onAppear {
//                        mediaPlayer.audio?.isMuted = false
//                        mediaPlayer.play()
//                    }
//                    .onDisappear {
//                        mediaPlayer.stop()
//                    }
//                    .overlay(
//                        CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer),
//                        alignment: .bottomTrailing
//                    )
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .onRotate { orientation in
//                if orientation.isValidInterfaceOrientation {
//                    isLandscape = orientation.isLandscape
//                }
//            }
//        }
//    }
//
//    // MARK: - Overlay
//
//    struct CameraOverlay: View {
//        let name: String
//        let mediaPlayer: VLCMediaPlayer
//
//        @State private var isMuted = false
//
//        private func toggleMute() {
//            isMuted.toggle()
//            mediaPlayer.audio?.isMuted = isMuted
//        }
//
//        var body: some View {
//            VStack {
//                Spacer()
//
//                HStack {
//                    Button(action: toggleMute) {
//                        Text(name)
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
//                    .padding(.bottom, 30)
//
//                    Button(action: toggleMute) {
//                        Image(systemName: isMuted ? "speaker.slash" : "speaker")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                    }
//                    .padding(.trailing, 30)
//                    .padding(.bottom, 30)
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//            .contentShape(Rectangle())
//            .onTapGesture {
//                toggleMute()
//            }
//        }
//    }
//}
