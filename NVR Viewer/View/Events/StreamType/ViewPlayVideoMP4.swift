//
//  ViewPlayVideoMP4.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/8/25.
//
import SwiftUI
import AVKit
import AVFoundation

struct ViewPlayVideoMP4: View {
    let urlString: String          // original m3u8 URL (kept for compatibility / unused now)
    let urlMp4String: String       // DIRECT MP4 URL from Frigate
    let frameTime: Double          // kept for compatibility (used as filename tag in DownloadView)

    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    let menuTextColor = Color.white

    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @State private var isLandscape: Bool = UIDevice.current.orientation.isLandscape
 
    @State private var showingAlert = false
    @State private var isFullScreen = false
    @State private var player: AVPlayer? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isReadyToPlay = false

    @State private var tempFolderURL: URL? = nil
    @State private var localVideoURL: URL? = nil

    @AppStorage("authType") var authType: AuthType = .none 
    
    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Main states

            if let player = player {
                if isReadyToPlay {
                    // ===========================
                    // MARK: - Ready, show video
                    // ===========================
                    if idiom == .pad {
                        VStack(spacing: 0) {

                            // MARK: Video (iPad)
                            VideoPlayer(player: player)
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: isLandscape ? 485 : 350)
                                .clipped()
                                .onDisappear {
                                    player.pause()
                                    cleanupTempFolder()
                                }
                                .onRotate { orientation in
                                    if orientation.isValidInterfaceOrientation {
                                        isLandscape = orientation.isLandscape
                                    }
                                }

                            // MARK: Download row (same layout as before)
                            //if isMP4InvalidURL(urlMp4String) {
                            if isValidMp4URL(urlMp4String) {
                                DownloadView(urlString: urlMp4String, fileName: frameTime, showProgress: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(
                                        BottomRoundedRectangle(radius: 22)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        cBlue.opacity(0.6),
                                                        cBlue.opacity(0.95)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: cBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)

                    } else {
                        VStack(spacing: 0) {

                            // MARK: Video (iPhone)
                            VideoPlayer(player: player)
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: isLandscape ? 350 : 210)
                                .clipped()
                                .onDisappear {
                                    player.pause()
                                    cleanupTempFolder()
                                }
                                .onRotate { orientation in
                                    if orientation.isValidInterfaceOrientation {
                                        isLandscape = orientation.isLandscape
                                    }
                                }

                            // MARK: Download row (same layout as before)
                            if isMP4InvalidURL(urlMp4String) {
                                DownloadView(urlString: urlMp4String, fileName: frameTime, showProgress: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(
                                        BottomRoundedRectangle(radius: 22)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        cBlue.opacity(0.6),
                                                        cBlue.opacity(0.95)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: cBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                } else {
                    // Video file is downloaded but we're still finalizing
                    ProgressView("Finalizing Video…")
                        .padding()
                }

            } else if isLoading {
                // ===========================
                // MARK: - Loading glass card
                // ===========================
                VStack(spacing: 8) {

                    if idiom == .pad {
                        ZStack {
                            // Glass card background
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.35),
                                            Color.gray.opacity(0.20)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                                )
                                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)

                            // Content: spinner + text
                            HStack(spacing: 12) {
                                Spacer()

                                ProgressView()
                                    .tint(cBlue)
                                    .scaleEffect(1.1)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Buffering Video…")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)

                                    if let errorMessage {
                                        Text(errorMessage)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.red.opacity(0.95))
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        Text("Preparing your clip for playback")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(1))
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: isLandscape ? 570 : 420)

                    } else {
                        ZStack {
                            // Glass card background
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.35),
                                            Color.gray.opacity(0.20)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                                )
                                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)

                            // Content: spinner + text
                            HStack(spacing: 12) {
                                Spacer()

                                ProgressView()
                                    .tint(cBlue)
                                    .scaleEffect(1.1)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Buffering Video…")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)

                                    if let errorMessage {
                                        Text(errorMessage)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.red.opacity(0.95))
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        Text("Preparing your clip for playback")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(1))
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: isLandscape ? 420 : 260)
                    }
                }
                .frame(maxWidth: .infinity)

            } else {
                // ===========================
                // MARK: - Initial / error
                // ===========================
                if idiom == .pad {
                    ZStack {
                        // Glass card background
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.35),
                                        Color.gray.opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                        
                        // Content: spinner + text
                        HStack(spacing: 12) {
                            Spacer()
                            
                            ProgressView()
                                .tint(cBlue)
                                .scaleEffect(1.1)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preparing Video")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.red.opacity(0.95))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .frame(height: isLandscape ? 570 : 420)
                } else {
                    ZStack {
                        // Glass card background
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.35),
                                        Color.gray.opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                        
                        // Content: spinner + text
                        HStack(spacing: 12) {
                            Spacer()
                            
                            ProgressView()
                                .tint(cBlue)
                                .scaleEffect(1.1)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Preparing Video")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.red.opacity(0.95))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .frame(height: isLandscape ? 420 : 260)
                }

            }
        }
        .modifier(CardBackground2())
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .task {
            await startMP4DownloadAndPlayback()
        }
    }

    // ===================================================
    // MARK: - Orchestrator: Download MP4 then Play
    // ===================================================
    private func startMP4DownloadAndPlayback() async {
        // Avoid duplicate work
        guard !isLoading, player == nil else {
            return
        }
  
        // Basic URL validation
        guard !urlMp4String.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let remoteURL = URL(string: urlMp4String) else {
            errorMessage = "Invalid MP4 URL"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            var jwt = ""
            switch authType {
            case .none:
                break
            case .bearer:
                jwt = try generateSyncJWTBearer()
            case .frigate:
                jwt = try generateSyncJWTFrigate()
            case .cloudflare:
                break
            case .custom:
                break
            }
             
            let downloader = MP4Downloader2()
            let result = try await downloader.downloadMP4(
                remoteURL: remoteURL,
                jwtToken: jwt
            )

            DispatchQueue.main.async {
                self.tempFolderURL = result.tempFolder
                self.localVideoURL = result.localFile
 
                let item = AVPlayerItem(url: result.localFile)
                self.player = AVPlayer(playerItem: item)

                self.isLoading = false
                self.isReadyToPlay = true
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "MP4 download failed: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }


    // ===================================================
    // MARK: - Cleanup
    // ===================================================
    private func cleanupTempFolder() {
        guard let folder = tempFolderURL else { return }
        do {
            try FileManager.default.removeItem(at: folder)
            //print("[DEBUG] 🧹 Temp folder deleted: \(folder.path)")
        } catch {
            Log.error(page: "ViewPlayVideoMP4", fn: "cleanupTempFolder", "Failed to delete temp folder: \(error)")
        }
        tempFolderURL = nil
        localVideoURL = nil
    }
}

// =======================================================
// MARK: - Optional AVPlayerViewController Wrapper
// =======================================================

struct PlayerViewControllerMP4: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false  // customize if you want controls
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}
}

// =======================================================
// MARK: - MP4Downloader2
// =======================================================
private let appGroupDefaults: UserDefaults = UserDefaults(suiteName: "group.com.viewu.app") ?? .standard

final class MP4Downloader2 {

    @AppStorage("authType") var authType: AuthType = .none
    //@AppStorage("cloudFlareClientId") private var cloudFlareClientId: String = ""
    @AppStorage("cloudFlareClientId", store: appGroupDefaults)  private var cloudFlareClientId: String = ""
    //@AppStorage("cloudFlareSecret") private var cloudFlareSecret: String = ""
    @AppStorage("cloudFlareClientSecret", store: appGroupDefaults) private var cloudFlareSecret: String = ""
    
    struct Result {
        let localFile: URL
        let tempFolder: URL
    }

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        // Accept self-signed certs for IP/FQDN (download only)
        self.session = URLSession(
            configuration: config,
            delegate: SSLBypassDelegate(),
            delegateQueue: nil
        )
    }

    func downloadMP4(
        remoteURL: URL,
        jwtToken: String
    ) async throws -> Result {
 
        // Create temp folder for this download
        let tempFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("mp4_download_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)

        let localFileURL = tempFolder.appendingPathComponent("video.mp4")

        var req = URLRequest(url: remoteURL)
        req.httpMethod = "GET"

        if !jwtToken.isEmpty {
            let preview = String(jwtToken.prefix(12))
            req.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        switch authType {
        case .none:
            break
        case .bearer, .frigate:
            break
        case .cloudflare:
//            req.setValue(clientId, forHTTPHeaderField: "CF-Access-Client-Id")
//            req.setValue(clientSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
            req.setValue(cloudFlareClientId, forHTTPHeaderField: "CF-Access-Client-Id")
            req.setValue(cloudFlareSecret,   forHTTPHeaderField: "CF-Access-Client-Secret")
        case .custom:
            break
        }
          
        req.setValue("AVPlayer/1.0", forHTTPHeaderField: "User-Agent")
 
        let (tempFile, response) = try await session.download(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
 
        if http.statusCode != 200 {
            // Try to capture a snippet of the body for diagnostics
            var bodySnippet = "<no body>"
            do {
                let data = try Data(contentsOf: tempFile)
                if let s = String(data: data, encoding: .utf8) {
                    bodySnippet = String(s.prefix(400))
                } else {
                    bodySnippet = "<non-UTF8 body, size=\(data.count) bytes>"
                }
            } catch {
                bodySnippet = "<failed to read body: \(error)>"
            }

            let msg = "HTTP \(http.statusCode) while downloading MP4. Body snippet: \(bodySnippet)"
            //print("[DEBUG] [MP4Downloader2] ERROR: \(msg)")

            throw NSError(
                domain: "MP4Downloader2",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }
 
        // Move from temp URL into our folder as video.mp4
        try? FileManager.default.removeItem(at: localFileURL)
        try FileManager.default.moveItem(at: tempFile, to: localFileURL)

        return Result(localFile: localFileURL, tempFolder: tempFolder)
    }
}

