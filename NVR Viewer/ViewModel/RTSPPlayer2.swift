//
//  RTSPPlayer2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/30/24.
//

import Foundation
import MobileVLCKit
import SwiftUI

struct VlcPlayeyRTSP2: UIViewRepresentable{
    
    let urlString: String
    let mediaPlayer : VLCMediaPlayer
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VlcPlayeyRTSP2>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        
        return PlayerUIView2(frame: .zero, urlString: urlString, mediaPlayer: mediaPlayer)
    }
}

class PlayerUIView2: UIView, VLCMediaPlayerDelegate, ObservableObject{
    
    //override
    init(frame: CGRect, urlString: String, mediaPlayer : VLCMediaPlayer) {
        
        super.init(frame: CGRect(x:0,y:0, width:350, height: 250))
        
        //DispatchQueue.main.async {
        DispatchQueue.global(qos: .userInteractive).async{
            
            //super.init(frame: UIScreen.screens[0].bounds)
            //super.init(frame: self.view.window?.windowScene?.screen.bounds.size)
            //super.init(frame: CGRect(x:0,y:0, width:350, height: 250))
            
            let url = URL(string: urlString)!
            let media = VLCMedia(url: url)
            
            //https://wiki.videolan.org/VLC_command-line_help
            media.addOption("--codec=avcodec")
            media.addOption("--avcodec-hw=any")
            media.addOption("--avcodec-fast=true")
            media.addOption("--glconv-glconv_cvpx")
            //        media.addOption("--avcodec-threads=0")
            media.addOption("--network-caching=100")
            media.addOption(":rtsp-caching=150")
            //        media.addOption("--rtsp-frame-buffer-size=200")
            media.addOption("--vout=ios")
            //        media.addOption("--glconv=glconv_cvpx")
            //        media.addOption("--rtsp-caching=100")
            //        media.addOption("--rtsp-tcp")
            //        media.addOption("--tcp-caching=150")
            //        media.addOption("--realrtsp-caching=150")
            //        media.addOption("--mms-timeout=6000")
            //        media.addOption("--h264-fps=15.0")
            //        media.addOption("--vcodec=h264")
            
            
            //        media.addOptions(
            //            [
            //                //"--rtsp-tcp": true,
            //                "codec":"avcodec",
            //                "avcodec-hw":"any", // none
            //                "avcodec-fast" : true,
            //                "avcodec-threads" : 0, // "1" 0=auto
            //                "network-caching": 300, //300, 500
            //                "rtsp-frame-buffer-size":100, //100, 500
            //                "vout": "ios",
            //                "glconv" : "glconv_cvpx",
            //                "rtsp-caching": 150, //rtsp-caching=
            //                "tcp-caching": 150, //tcp-caching=
            //                "realrtsp-caching": 150, //150, realrtsp-caching=
            //                //"--h264-fps": 20.0, //20.0
            //                "mms-timeout": 6000, //60000
            //            ]
            //        )
            
            mediaPlayer.media = media
            mediaPlayer.delegate = self
            mediaPlayer.drawable = self
            mediaPlayer.audio?.isMuted = true
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(mutating: ("16:9" as NSString).utf8String)
            
            //Logging
            let logger = VLCConsoleLogger()
            logger.level = .info
            //mediaPlayer.libraryInstance.loggers = [logger]
            //mediaPlayer.play()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

import SwiftUI
import MobileVLCKit

struct StreamRTSP2: View {

    let urlString: String
    let cameraName: String

    @State var mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()
    @State var flagMute = true
    @State var flagFull = false
    @State var isLoading = true

    let menuTextColor = Color.white
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)

    var body: some View {

        let pillShape = BottomRoundedRectangle(radius: 22)

        VStack(spacing: 0) {

            // MARK: Video + loading
            ZStack {
                // Loading gradient overlay
                if isLoading {
                    LinearGradient(
                        colors: [
                            cBlue.opacity(0.0),
                            cBlue.opacity(0.35),
                            cBlue.opacity(0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
                    .padding(0)
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.black.opacity(0.8))
                    .onAppear {
                        mediaPlayer.audio?.isMuted = flagMute
                        mediaPlayer.play()
                    }
                    .onDisappear {
                        mediaPlayer.stop()
                    }
            }
            .frame(maxWidth: .infinity)
            .clipped()

            // MARK: Bottom pill controls (Save-clip-style)
            HStack(spacing: 12) {

                // Left: icon + camera name
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.20))

                        Image(systemName: "video.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cameraName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Live RTSP stream")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                // Right: mute + fullscreen circular buttons
                HStack(spacing: 10) {

                    // Mute toggle
                    Button {
                        flagMute.toggle()
                        mediaPlayer.audio?.isMuted = flagMute
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.60))

                            Image(systemName: flagMute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(cBlue)
                        }
                        .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    // Fullscreen toggle
                    Button {
                        flagFull.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.60))

                            Image(systemName: "arrow.down.left.and.arrow.up.right.rectangle")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(cBlue)
                        }
                        .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        .orange.opacity(0.6),
                        .orange.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(pillShape)   // flat top, rounded bottom
            .overlay(
                ZStack {
                    // Outer border
                    pillShape
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)

                    // Inner border (slightly inset)
                    pillShape
                        .inset(by: 4)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                }
            )
            .shadow(color: cBlue.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .background(Color.white)
        .modifier(CardBackground2())
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .navigationDestination(isPresented: $flagFull) {
            ViewCameraFullScreen(urlString: urlString, cameraName: cameraName)
        }
    }

    struct CardBackground2: ViewModifier {
        func body(content: Content) -> some View {
            content
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
        }
    }
}
