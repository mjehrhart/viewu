//
//  ViewCameraHLSFullScreen.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 5/31/24.
//

import SwiftUI
import WebKit

@MainActor
struct ViewCameraHLSFullScreen: View {

    let urlString: String
    let cameraName: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Final HLS URL
    private var hlsURL: String {
        urlString + "/api/\(cameraName)?h=480"
    }

    // Use a slightly different contentMode depending on size class
    private var contentMode: ContentMode {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .fill
        } else {
            return .fit
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.clear, Color(red: 0.80, green: 0.80, blue: 0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Rotated HLS WebView
            Webview(url: hlsURL)
                .rotationEffect(.degrees(90))
                .aspectRatio(16 / 9, contentMode: contentMode)
                .frame(width: UIScreen.screenHeight, height: UIScreen.screenWidth)
                .ignoresSafeArea()
                .overlay(
                    CameraOverlay(name: cameraName),
                    alignment: .bottomTrailing
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Overlay

    struct CameraOverlay: View {
        let name: String

        var body: some View {
            HStack {
                VStack {
                    Spacer()
                    HStack {
                        Button(name) {
                            // tap currently does nothing; could be used later
                        }
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomTrailing
                        )
                        .padding(.bottom, 10)
                        .padding(.trailing, 110)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .background(Color.clear)
            .rotationEffect(.degrees(90)) // match the video rotation
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}
