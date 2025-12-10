//
//  ViewCamerasList.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import WebKit
import MobileVLCKit
import TipKit

@MainActor
struct ViewCamerasList: View {

    // 11/09/25
    @ObservedObject private var config = NVRConfigurationSuper2.shared()

    let title: String

    private let nvr = NVRConfig.shared()

    @AppStorage("developerModeIsOn") private var developerModeIsOn: Bool = false

    // Stream mode toggles (persisted in UserDefaults / used across app)
    @AppStorage("cameraSubStream")  private var cameraSubStream: Bool  = false
    @AppStorage("cameraRTSPPath")   private var cameraRTSPPath: Bool   = false
    @AppStorage("camerGo2Rtc")      private var camerGo2Rtc: Bool      = false
    @AppStorage("cameraHLS")        private var cameraHLS: Bool        = false

    // Use the dismiss action
    @Environment(\.dismiss) private var dismiss

    /// HLS + LAN + HTTPS combination that will fail on iOS with self-signed certs.
    private var hasHttpsLanHLS: Bool {
        guard cameraHLS else { return false } // only care if HLS is enabled
        let baseURL = nvr.getUrl()           // e.g. "https://192.168.1.152:8971"
        return isHttpsLanURL(baseURL)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // Tips when HLS isn't in the problematic configuration
                if !hasHttpsLanHLS {
                    ViewTipsLiveCameras(
                        title: "Live Cameras",
                        message: "You can change the camera stream from the Settings page. To reduce load times, use a sub-stream whenever possible."
                    )
                    .padding(15)
                }

                // 🔔 HLS + LAN + HTTPS warning banner
                if hasHttpsLanHLS {
                    Color.clear
                        .frame(height: 2)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Streams Will Not Play")
                                .font(.system(size: 13, weight: .semibold))

                            Text("iOS blocks HTTPS streams to IP addresses that use self-signed certificates. If your Frigate server uses a self-signed cert on an IP (for example, https://192.168.1.150:8971), HLS video may not display. In this case, use RTSP via Go2RTC for streaming and ensure it is properly configured in your Frigate config file.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(12) 
                }

                // MARK: - go2rtc.streams (explicit streams dictionary)
                if let streams = config.item.go2rtc.streams,
                   cameraRTSPPath {
                    ForEach(streams.keys.sorted(), id: \.self) { key in
                        // Only show enabled cameras
                        if config.item.cameras[key]?.enabled == true {
                            renderRTSPFromStreams(key: key, streams: streams[key] ?? [])
                        }
                    }
                }

                // MARK: - go2rtc from camera ffmpeg inputs
                if camerGo2Rtc {
                    ForEach(config.item.cameras.keys.sorted(), id: \.self) { cameraName in
                        if let camera = config.item.cameras[cameraName],
                           camera.enabled {
                            renderGo2RTCCamera(cameraName: cameraName, camera: camera)
                        }
                    }
                }

                // MARK: - HLS
                if cameraHLS {
                    ForEach(config.item.cameras.keys.sorted(), id: \.self) { cameraName in
                        if config.item.cameras[cameraName]?.enabled == true {
                            let baseURL = nvr.getUrl()
                            HLSPlayer2(
                                urlString: baseURL,
                                cameraName: cameraName,
                                flagFull: false
                            )
                            if developerModeIsOn {
                                Text(baseURL + "/api/\(cameraName)?h=480")
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollIndicators(.hidden)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
    }

    // MARK: - Render helpers

    /// Render RTSP streams from go2rtc.streams dictionary.
    private func renderRTSPFromStreams(key: String, streams: [String]) -> some View {
        Group {
            if cameraSubStream {
                // Only show sub-stream entries for keys containing "sub"
                if key.contains("sub") {
                    ForEach(streams, id: \.self) { url in
                        if url.hasPrefix("rtsp") {
                            let name = key + "_sub"
                            cameraStreamView(url: url, cameraName: name)
                        }
                    }
                }
            } else {
                // Show non-sub entries
                if !key.contains("sub") {
                    ForEach(streams, id: \.self) { url in
                        if url.hasPrefix("rtsp") {
                            cameraStreamView(url: url, cameraName: key)
                        }
                    }
                }
            }
        }
    }

    /// Render RTSP streams using go2rtc via ffmpeg inputs on cameras.
    private func renderGo2RTCCamera(cameraName: String, camera: Cameras2) -> some View {
        Group {
            ForEach(camera.ffmpeg.inputs, id: \.self) { input in
                let url = verifyGo2RTCUrl(urlString: input.path)

                if cameraSubStream {
                    // Sub-streams only (name or URL contains "sub")
                    if url.contains("sub") || cameraName.contains("sub") {
                        if url.hasPrefix("rtsp") {
                            let name = cameraName + "_sub"
                            cameraStreamView(url: url, cameraName: name)
                        }
                    }
                } else {
                    // Main streams only (URL doesn't contain "sub")
                    if !url.contains("sub"), url.hasPrefix("rtsp") {
                        cameraStreamView(url: url, cameraName: cameraName)
                    }
                }
            }
        }
    }

    /// Shared stream renderer with optional debug URL text.
    @ViewBuilder
    private func cameraStreamView(url: String, cameraName: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StreamRTSP2(
                urlString: url,
                cameraName: cameraName
            )
            .padding(.vertical, 4)

            if developerModeIsOn {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(url)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - URL helpers

    /// Replace 127.0.0.1 / localhost in a go2rtc URL with the configured NVR IP.
    func verifyGo2RTCUrl(urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host,
              let scheme = url.scheme else {
            return urlString
        }

        // Only fix localhost-style hosts
        guard host == "127.0.0.1" || host == "localhost" else {
            return urlString
        }

        let newHost = nvr.getIP()
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = newHost
        comps.port = url.port
        comps.path = url.path
        comps.query = url.query

        return comps.url?.absoluteString ?? urlString
    }
}
