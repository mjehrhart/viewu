 
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
    let headers: [String: String]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Your existing orientation approach
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    private var hlsURL: String {
        let base = urlString.hasSuffix("/") ? String(urlString.dropLast()) : urlString
        return base + "/api/\(cameraName)?h=480"
    }

    private var contentMode: ContentMode {
        (horizontalSizeClass == .regular && verticalSizeClass == .regular) ? .fill : .fit
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.clear, Color(red: 0.80, green: 0.80, blue: 0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
 
            Webview(url: hlsURL, headers: headers)
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(
                    width: isLandscape ?  UIScreen.screenWidth : UIScreen.screenHeight,
                    height: isLandscape ? UIScreen.screenHeight : UIScreen.screenWidth
                )
                .ignoresSafeArea()
                .rotationEffect(isLandscape ? .degrees(0) : .degrees(90))
                .overlay(CameraOverlay(name: cameraName), alignment: .bottomTrailing)
                .onAppear {
                        // First reliable update after view is on-screen
                        let o = UIDevice.current.orientation
                        if o != .unknown { isLandscape = o.isLandscape }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        let o = UIDevice.current.orientation
                        // Filter out non-useful orientations so you don't flip incorrectly
                        if o == .landscapeLeft || o == .landscapeRight {
                            isLandscape = true
                        } else if o == .portrait || o == .portraitUpsideDown {
                            isLandscape = false
                        }
                    }
             
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
