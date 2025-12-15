//
//  ViewCameraRTSPFullScreen.swift
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

    private let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    private let menuTextColor = Color.white

    @State private var mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()

    // Your existing orientation approach
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                LinearGradient(
                    colors: [cBlue.opacity(0.6), .orange.opacity(0.6), cBlue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // VIDEO PLANE (VLC + overlay) — rotate this ONCE
                ZStack(alignment: .bottom) {

                    // RTSP Video
                    VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()

                    // Bottom overlay bar (covers bottom of the stream)
                    CameraOverlayBar(
                        name: cameraName,
                        mediaPlayer: mediaPlayer
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)      // keeps it off the very edge
                    .zIndex(999)               // force above VLC
                }
                // Important: size swap when rotated, so it stays centered and fills
                .frame(
                    width: isLandscape ? w : h,
                    height: isLandscape ? h : w
                )
                .rotationEffect(isLandscape ? .degrees(0) : .degrees(90))
                .position(x: w / 2, y: h / 2)
            }
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                mediaPlayer.audio?.isMuted = false
                mediaPlayer.play()
            }
            .onDisappear {
                mediaPlayer.stop()
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
            .onRotate { orientation in
                guard orientation.isValidInterfaceOrientation else { return }
                isLandscape = orientation.isLandscape
            }
        }
    }
}

// MARK: - Bottom Bar Overlay

@MainActor
private struct CameraOverlayBar: View {
    let name: String
    let mediaPlayer: VLCMediaPlayer

    @State private var isMuted = false

    private func toggleMute() {
        isMuted.toggle()
        mediaPlayer.audio?.isMuted = isMuted
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button(action: toggleMute) {
                Image(systemName: isMuted ? "speaker.slash" : "speaker")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(.black.opacity(0.35), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}




////
////  ViewCameraFullScreen.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 5/7/24.
////
// 
//import SwiftUI
//import MobileVLCKit
// 
//@MainActor
//struct ViewCameraRTSPFullScreen: View {
//    
//    let urlString: String 
//    let cameraName: String
//    
//    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
//    let menuTextColor = Color.white
//    
//    //@State var orientation = UIDevice.current.orientation
//    @State var mediaPlayer : VLCMediaPlayer = VLCMediaPlayer()
//    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
//    
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
// 
//    var body: some View {
//        
//        
//        VStack{
//            
//            ZStack{
//                
//                LinearGradient(
//                    colors: [cBlue.opacity(0.6), .orange.opacity(0.6), cBlue.opacity(0.6)],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                
//                Text("Loading: \(urlString)")
//                    .rotationEffect( isLandscape ? .degrees(0) : .degrees(90))
//                    .labelStyle(VerticalLabelStyle(show: false))
//                    .foregroundStyle(menuTextColor)
//                    .onRotate { orientation in
//                        if orientation.isValidInterfaceOrientation {
//                            isLandscape = orientation.isLandscape
//                        }
//                    }
//                
//                VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
//                    .rotationEffect( isLandscape ? .degrees(0) : .degrees(90))
//                    //.aspectRatio(16/9, contentMode: .fill)
//                    .aspectRatio(contentMode: .fill)
//                    //.edgesIgnoringSafeArea(.all)
//                    .onAppear(){
//                        mediaPlayer.audio?.isMuted = false
//                        mediaPlayer.play()
//                    }
//                    .onDisappear(){
//                        mediaPlayer.stop()
//                    }
//                    //.overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .bottomTrailing)
//                    //.overlay(CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer), alignment: .top)
//                    .safeAreaInset(edge: .top) {
//                        CameraOverlay(name: cameraName, mediaPlayer: mediaPlayer)
//                    }
//                    .onRotate { orientation in
//                        if orientation.isValidInterfaceOrientation {
//                            isLandscape = orientation.isLandscape
//                        }
//                    }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            
//        }
//    }
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
//            HStack(spacing: 12) {
//                Text(name)
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                    .foregroundStyle(.white)
//                    .lineLimit(1)
//
//                Spacer()
//
//                Button(action: toggleMute) {
//                    Image(systemName: isMuted ? "speaker.slash" : "speaker")
//                        .font(.title3)
//                        .foregroundStyle(.white)
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 12)
//                        .background(.black.opacity(0.35), in: Capsule())
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//            .background(.black.opacity(0.25))
//            .contentShape(Rectangle())
//        }
//    }
//
//    
////        struct CameraOverlay: View {
////            let name: String
////            let mediaPlayer: VLCMediaPlayer
////    
////            @State private var isMuted = false
////    
////            private func toggleMute() {
////                isMuted.toggle()
////                mediaPlayer.audio?.isMuted = isMuted
////            }
////    
////            var body: some View {
////                VStack {
////                    Spacer()
////    
////                    HStack {
////                        Button(action: toggleMute) {
////                            Text(name)
////                                .font(.title)
////                                .fontWeight(.bold)
////                                .foregroundColor(.white)
////                        }
////                        .frame(maxWidth: .infinity, alignment: .bottomLeading)
////                        .padding(.bottom, 30)
////                        .padding(.leading, 30)
////                        
////                        Button(action: toggleMute) {
////                            Image(systemName: isMuted ? "speaker.slash" : "speaker")
////                                .font(.title)
////                                .fontWeight(.bold)
////                                .foregroundColor(.white)
////                        }
////                        .padding(.trailing, 230)
////                        .padding(.bottom, 30)
////                    }
////                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
////                    .background(.orange.opacity(0.4))
////                }
////                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
////                .contentShape(Rectangle())
////                .background(false ? .blue.opacity(0.9) : .green.opacity(0.9))
////                //.rotationEffect( false ? .degrees(0) : .degrees(90))
////                .onTapGesture {
////                    toggleMute()
////                }
////            }
////        }
//}
// 
