//
//  VideoPlayStreamM3U8.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/8/25.
//

import SwiftUI
import AVKit
import AVFoundation

struct ViewVideoPlayStreamM3U8: View {
    let urlString: String
    let urlMp4String: String
    let frameTime: Double

    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)

    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    @State private var isLandscape = UIDevice.current.orientation.isLandscape
    @State private var player: AVPlayer?
    @State private var playerItemObservation: NSKeyValueObservation?

    @State private var showPlayOverlay = true
    @State private var isReadyToPlay = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // 🔐 Self-signed cert support
    static let playbackSession = AVURLSessionHelper.makeSession()

    // 🔐 Auth configuration (mirror MP4 view / downloader)
    @AppStorage("authType") private var authType: AuthType = .none
    @AppStorage("cloudFlareClientId") private var cloudFlareClientId: String = ""
    @AppStorage("cloudFlareSecret") private var cloudFlareSecret: String = ""

    var body: some View {
        VStack(spacing: 0) {
            videoSection
        }
        .modifier(CardBackground2())
        .padding(.horizontal, 20)
        .task {
            await setupStream()
        }
    }

    // MARK: - UI
    @ViewBuilder
    private var videoSection: some View {
        if let player {
            ZStack {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: idiom == .pad ? (isLandscape ? 485 : 350) : (isLandscape ? 350 : 210))
                    .clipped()
                    .onDisappear { player.pause() }
                    .onRotate { if $0.isValidInterfaceOrientation { isLandscape = $0.isLandscape } }

                if showPlayOverlay {
                    // Optionally restore overlay here if you want tap-to-play
                }
            }

            if isMP4InvalidURL(urlMp4String) {
                mp4DownloadButton
            }

        } else if isLoading {
            bufferingUI

        } else if let errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()

        } else {
            Text("Preparing Video…")
                .padding()
        }
    }

    private var mp4DownloadButton: some View {
        DownloadView(urlString: urlMp4String, fileName: frameTime, showProgress: false)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                BottomRoundedRectangle(radius: 22)
                    .fill(
                        LinearGradient(
                            colors: [cBlue.opacity(0.6), cBlue.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: cBlue.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var bufferingUI: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(
                LinearGradient(colors: [.gray.opacity(0.35), .gray.opacity(0.18)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            ProgressView("Buffering…")
                .tint(cBlue)
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: idiom == .pad ? 420 : 280)
    }

    // MARK: - Setup Stream (with auth headers)
    private func setupStream() async {
        guard player == nil else { return }

        guard
            !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let remoteURL = URL(string: urlString)
        else {
            errorMessage = "Invalid stream URL"
            return
        }

        isLoading = true
        errorMessage = nil

        // ===== Build auth headers (same logic as MP4 path) =====
        var jwt: String = ""

        switch authType {
        case .none:
            break

        case .bearer:
            if let token = try? generateSyncJWTBearer() {
                jwt = token
            }

        case .frigate:
            if let token = try? generateSyncJWTFrigate() {
                jwt = token
            }

        case .cloudflare:
            // Cloudflare uses service token headers, not JWT here
            break

        case .custom:
            // Reserved for any custom auth you add later
            break
        }

        var headers: [String: String] = [
            "User-Agent": "AVPlayer/1.0"
        ]

        if !jwt.isEmpty {
            headers["Authorization"] = "Bearer \(jwt)"
        }

        if authType == .cloudflare {
            if !cloudFlareClientId.isEmpty {
                headers["CF-Access-Client-Id"] = cloudFlareClientId
            }
            if !cloudFlareSecret.isEmpty {
                headers["CF-Access-Client-Secret"] = cloudFlareSecret
            }
        }

        // AVURLAsset with per-request HTTP headers (used for playlist + segments)
        let asset = AVURLAsset(
            url: remoteURL,
            options: [
                "AVURLAssetHTTPHeaderFieldsKey": headers
            ]
        )

        // SSL bypass for AVAsset loading
        asset.resourceLoader.setDelegate(Self.playbackSession.resourceLoaderDelegate, queue: .main)

        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)

        playerItemObservation = item.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    isReadyToPlay = true
                    isLoading = false
                case .failed:
                    errorMessage = "Stream failed: \(item.error?.localizedDescription ?? "unknown")"
                    isLoading = false
                default:
                    break
                }
            }
        }

        DispatchQueue.main.async {
            self.player = newPlayer
            self.isLoading = false  // UI now loads instantly
        }
    }
}

// MARK: - Self-Signed Helper
final class AVURLSessionHelper {
    static func makeSession() -> (session: URLSession, resourceLoaderDelegate: SSLBypassDelegateHLS) {
        let delegate = SSLBypassDelegateHLS()
        let config = URLSessionConfiguration.default
        return (
            URLSession(configuration: config, delegate: delegate, delegateQueue: nil),
            delegate
        )
    }
}

// MARK: - SSL Bypass for HLS Key Requests
final class SSLBypassDelegateHLS: NSObject, URLSessionDelegate, AVAssetResourceLoaderDelegate {

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func resourceLoader(_ loader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        // You're currently not intercepting/fulfilling here; just allow default loading.
        loadingRequest.redirect = nil
        loadingRequest.response = nil
        return false
    }
}


////
////  VideoPlayStreamM3U8.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 12/8/25.
////
//
//import SwiftUI
//import AVKit
//import AVFoundation
//
//struct ViewVideoPlayStreamM3U8: View {
//    let urlString: String
//    let urlMp4String: String
//    let frameTime: Double
//
//    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
//
//    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
//
//    @State private var isLandscape = UIDevice.current.orientation.isLandscape
//    @State private var player: AVPlayer?
//    @State private var playerItemObservation: NSKeyValueObservation?
//
//    @State private var showPlayOverlay = true
//    @State private var isReadyToPlay = false
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    // 🔐 Self-signed cert support
//    static let playbackSession = AVURLSessionHelper.makeSession()
//
//    var body: some View {
//        VStack(spacing: 0) {
//            videoSection
//        }
//        .modifier(CardBackground2())
//        .padding(.horizontal, 20)
//        .task {
//            await setupStream()
//        }
//    }
//
//    // MARK: - UI
//    @ViewBuilder
//    private var videoSection: some View {
//        if let player {
//            ZStack {
//                VideoPlayer(player: player)
//                    .aspectRatio(16/9, contentMode: .fill)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: idiom == .pad ? (isLandscape ? 485 : 350) : (isLandscape ? 350 : 210))
//                    .clipped()
//                    .onDisappear { player.pause() }
//                    .onRotate { if $0.isValidInterfaceOrientation { isLandscape = $0.isLandscape } }
//
//                if showPlayOverlay {
////                    Color.black.opacity(0.4)
////                        .overlay(
////                            VStack(spacing: 12) {
////                                Image(systemName: "play.fill")
////                                    .font(.system(size: 48))
////                                    .foregroundColor(.white)
////                                Text("Tap to Play")
////                                    .foregroundColor(.white)
////                                    .font(.headline)
////                            }
////                        )
////                        .onTapGesture {
////                            showPlayOverlay = false
////                            player.play()
////                        }
//                }
//            }
//
//            if isMP4InvalidURL(urlMp4String) {
//                mp4DownloadButton
//            }
//
//        } else if isLoading {
//            bufferingUI
//
//        } else if let errorMessage {
//            Text(errorMessage).foregroundColor(.red).padding()
//
//        } else {
//            Text("Preparing Video…").padding()
//        }
//    }
//
//    private var mp4DownloadButton: some View {
//        DownloadView(urlString: urlMp4String, fileName: frameTime, showProgress: false)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(.horizontal, 10)
//            .padding(.vertical, 10)
//            .background(
//                BottomRoundedRectangle(radius: 22)
//                    .fill(
//                        LinearGradient(
//                            colors: [cBlue.opacity(0.6), cBlue.opacity(0.95)],
//                            startPoint: .topLeading, endPoint: .bottomTrailing
//                        )
//                    )
//            )
//            .shadow(color: cBlue.opacity(0.35), radius: 8, x: 0, y: 4)
//    }
//
//    private var bufferingUI: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 22).fill(
//                LinearGradient(colors: [.gray.opacity(0.35), .gray.opacity(0.18)],
//                               startPoint: .topLeading, endPoint: .bottomTrailing)
//            )
//            ProgressView("Buffering…")
//                .tint(cBlue)
//                .scaleEffect(1.2)
//        }
//        .frame(maxWidth: .infinity)
//        .frame(height: idiom == .pad ? 420 : 280)
//    }
//
//    // MARK: - Setup Stream
//    private func setupStream() async {
//        guard player == nil else { return }
//
//        guard let remoteURL = URL(string: urlString), !urlString.isEmpty else {
//            errorMessage = "Invalid stream URL"
//            return
//        }
//
//        isLoading = true
//
//        // 🔥 FAST: Do NOT preflight / fetch m3u8 here
//        let asset = AVURLAsset(url: remoteURL, options: [
//            "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "AVPlayer/1.0"]
//        ])
//
//        // SSL bypass for AVAsset loading
//        asset.resourceLoader.setDelegate(Self.playbackSession.resourceLoaderDelegate, queue: .main)
//
//        let item = AVPlayerItem(asset: asset)
//        let newPlayer = AVPlayer(playerItem: item)
//
//        playerItemObservation = item.observe(\.status, options: [.new]) { item, _ in
//            DispatchQueue.main.async {
//                switch item.status {
//                case .readyToPlay:
//                    isReadyToPlay = true
//                    isLoading = false
//                case .failed:
//                    errorMessage = "Stream failed: \(item.error?.localizedDescription ?? "unknown")"
//                    isLoading = false
//                default: break
//                }
//            }
//        }
//
//        DispatchQueue.main.async {
//            self.player = newPlayer
//            self.isLoading = false  // UI now loads instantly
//        }
//    }
//}
//
//// MARK: - Self-Signed Helper
//final class AVURLSessionHelper {
//    static func makeSession() -> (session: URLSession, resourceLoaderDelegate: SSLBypassDelegateHLS) {
//        let delegate = SSLBypassDelegateHLS()
//        let config = URLSessionConfiguration.default
//        return (
//            URLSession(configuration: config, delegate: delegate, delegateQueue: nil),
//            delegate
//        )
//    }
//}
//
//// MARK: - SSL Bypass for HLS Key Requests
//final class SSLBypassDelegateHLS: NSObject, URLSessionDelegate, AVAssetResourceLoaderDelegate {
//
//    func urlSession(_ session: URLSession,
//                    didReceive challenge: URLAuthenticationChallenge,
//                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        if let trust = challenge.protectionSpace.serverTrust {
//            completionHandler(.useCredential, URLCredential(trust: trust))
//        } else {
//            completionHandler(.performDefaultHandling, nil)
//        }
//    }
//
//    // Allows HLS key requests over self-signed cert
//    func resourceLoader(_ loader: AVAssetResourceLoader,
//                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//        loadingRequest.redirect = nil
//        loadingRequest.response = nil
//        if let url = loadingRequest.request.url,
//           url.scheme == "https", let trust = loadingRequest.request.mainDocumentURL?.host {
//            // just bypass
//        }
//        return false
//    }
//}
