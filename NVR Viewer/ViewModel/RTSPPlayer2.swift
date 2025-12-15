//
//  RTSPPlayer2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/30/24.
//

import Foundation
import SwiftUI
import MobileVLCKit

// MARK: - UIViewRepresentable wrapper

struct VlcPlayeyRTSP2: UIViewRepresentable {

    let urlString: String
    let mediaPlayer: VLCMediaPlayer

    func makeUIView(context: Context) -> UIView {
        PlayerUIView2(frame: .zero, urlString: urlString, mediaPlayer: mediaPlayer)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // If you ever need to respond to urlString / mediaPlayer changes,
        // do it here.
    }
}

// MARK: - Underlying UIView + VLCMediaPlayerDelegate

final class PlayerUIView2: UIView, VLCMediaPlayerDelegate {

    init(frame: CGRect, urlString: String, mediaPlayer: VLCMediaPlayer) {
        // Let SwiftUI decide sizing externally; use the incoming frame.
        super.init(frame: frame)

        guard let url = URL(string: urlString) else {
            // Invalid URL; nothing to configure
            return
        }

        let media = VLCMedia(url: url)

        // Tweak VLC options as needed
        media.addOption("--codec=avcodec")
        media.addOption("--avcodec-hw=any")
        media.addOption("--avcodec-fast=true")
        media.addOption("--glconv-glconv_cvpx")
        media.addOption("--network-caching=100")
        media.addOption(":rtsp-caching=150")
        media.addOption("--vout=ios")

        mediaPlayer.media = media
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self
        mediaPlayer.audio?.isMuted = true

        mediaPlayer.videoAspectRatio = UnsafeMutablePointer<Int8>(
            mutating: ("16:9" as NSString).utf8String
        )

        // Optional logger
        let logger = VLCConsoleLogger()
        logger.level = .info
        // mediaPlayer.libraryInstance.loggers = [logger] // if you want logs
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - VLCMediaPlayerDelegate hooks (optional)

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        // If you want, you can use this callback to notify SwiftUI that loading is done.
        // e.g. when state == .playing, toggle an `isLoading` flag via a callback/closure.
    }
}

// MARK: - SwiftUI wrapper for streaming view

struct ViewRTSPTile: View {

    let urlString: String
    let cameraName: String

    @State private var mediaPlayer = VLCMediaPlayer()
    @State private var flagMute = true
    @State private var flagFull = false
    @State private var isLoading = true   // currently never updated

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
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(Color.black.opacity(0.8))
                    .onAppear {
                        mediaPlayer.audio?.isMuted = flagMute
                        mediaPlayer.play()
                        // TODO: consider flipping `isLoading` to false via a delegate
                        // when VLC actually starts playing, instead of here.
                    }
                    .onDisappear {
                        mediaPlayer.stop()
                    }
            }
            .frame(maxWidth: .infinity)
            .clipped()

            // MARK: Bottom pill controls
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
            
            ViewCameraRTSPFullScreen(urlString: urlString, cameraName: cameraName)
            
//            VlcPlayeyRTSP2(urlString: urlString, mediaPlayer: mediaPlayer)
//                .padding(0)
//                .aspectRatio(16 / 9, contentMode: .fit)
//                .background(Color.black.opacity(0.8))
//                .onAppear {
//                    mediaPlayer.audio?.isMuted = flagMute
//                    mediaPlayer.play()
//                    // TODO: consider flipping `isLoading` to false via a delegate
//                    // when VLC actually starts playing, instead of here.
//                }
//                .onDisappear {
//                    mediaPlayer.stop()
//                }
            
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
