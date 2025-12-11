import SwiftUI
import AVKit
import AVFoundation 

struct ViewPlayVideoM3U8Segments: View {
    let urlString: String          // original m3u8 URL (unused now)
    let urlMp4String: String       // DIRECT MP4 URL from Frigate
    let frameTime: Double          // kept for compatibility (unused here) 
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)
    let menuTextColor = Color.white
     
    var developerModeIsOn: Bool = UserDefaults.standard.bool(forKey: "developerModeIsOn")
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
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
              
            if let player = player {
                 
                if isReadyToPlay {
                     
                    if idiom == .pad {
                        VStack(spacing: 0) {
                            
                            // MARK: Video
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
                            
                            //if isMP4InvalidURL(urlMp4String) {
                            if isValidMp4URL(urlMp4String) {
                                
                                DownloadView(urlString: urlMp4String, fileName: frameTime, showProgress: false)
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
                    else {
                        VStack(spacing: 0) {
                            
                            // MARK: Video
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
                            
                            if isMP4InvalidURL(urlMp4String) {
                                
                                DownloadView(urlString: urlMp4String, fileName: frameTime, showProgress: false)
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
                    // video downloaded but UI hasn’t marked ready yet
                    ProgressView("Finalizing Video…")
                        .padding()
                }
            } else if isLoading {
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
                        //.frame(height: 290)   // keep same height as video player + sub menu
                        .frame(height: isLandscape ? 420 : 280)
                    }
                }
                .frame(maxWidth: .infinity)

            } else {
                VStack {
                    Text("Preparing Video")
                        .padding()
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
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
         
        guard !isLoading, player == nil else { return }
 
        guard !urlMp4String.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              
                  
            let remoteURL = URL(string: urlMp4String) else {
            
            errorMessage = "Invalid MP4 URL"
            Log.shared().print(page: "ViewPlayVideoM3U8Segments", fn: "startMP4DownloadAndPlayback", type: "ERROR", text: "Invalid MP4 URL")
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
             
            let downloader = MP4Downloader()
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
                //print("[DEBUG] ✅ Local MP4 ready at \(result.localFile.path)")

            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "MP4 download failed: \(error.localizedDescription)"
                self.isLoading = false
                Log.shared().print(page: "ViewPlayVideoM3U8Segments", fn: "startMP4DownloadAndPlayback", type: "ERROR", text: "MP4 download failed: \(error.localizedDescription)")
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
            Log.shared().print(page: "ViewPlayVideoM3U8Segments", fn: "cleanupTempFolder", type: "ERROR", text: "Failed to delete temp folder: \(error)")
        }
        tempFolderURL = nil
        localVideoURL = nil
    }
}
 
// =======================================================
// MARK: - MP4Downloader support types from your snippet
// =======================================================

struct PlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false  // 👈 HERE
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}
}

final class MP4Downloader {

    @AppStorage("authType") var authType: AuthType = .none
    @AppStorage("cloudFlareClientId") private var cloudFlareClientId: String = ""
    @AppStorage("cloudFlareSecret") private var cloudFlareSecret: String = ""
    
    struct Result {
        let localFile: URL
        let tempFolder: URL
    }

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        // 🔐 Accept self-signed certs for 192.168.x.x / your domain
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

        let tempFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("mp4_download_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)
        //print("[DEBUG] 📁 MP4 temp folder created: \(tempFolder.path)")

        let localFileURL = tempFolder.appendingPathComponent("video.mp4")

        var req = URLRequest(url: remoteURL)
        req.httpMethod = "GET"
        
        switch authType {
        case .none:
            break
        case .bearer, .frigate:
            req.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        case .cloudflare:
            req.setValue(clientId, forHTTPHeaderField: "CF-Access-Client-Id")
            req.setValue(clientSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
        case .custom:
            break
        }
         
        req.setValue("AVPlayer/1.0", forHTTPHeaderField: "User-Agent")

        //print("[DEBUG] 🌐 GET (MP4) \(remoteURL.absoluteString)")
        //print("[DEBUG]   Headers: \(req.allHTTPHeaderFields ?? [:])")

        let (tempFile, response) = try await session.download(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
 
        if http.statusCode != 200 {
            let data = try? Data(contentsOf: tempFile)
            let snippet = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<non-text body>"
            //print("[DEBUG]   ❌ Non-200 MP4 response body snippet:\n\(snippet.prefix(200))")
            
            Log.shared().print(page: "ViewPlayVideoM3U8Segments", fn: "startMP4DownloadAndPlayback", type: "ERROR", text: "Non-200 MP4 response body snippet: \(snippet.prefix(200))")
            
            throw NSError(
                domain: "MP4Downloader",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode) while downloading MP4"]
            )
        }

        try? FileManager.default.removeItem(at: localFileURL)
        try FileManager.default.moveItem(at: tempFile, to: localFileURL)

        //print("[DEBUG] 💾 MP4 saved locally as: \(localFileURL.lastPathComponent)")
        return Result(localFile: localFileURL, tempFolder: tempFolder)
    }
}

// =======================================================
// MARK: - Self-Signed / IP HTTPS Bypass (DOWNLOAD ONLY)
// =======================================================

final class SSLBypassDelegate: NSObject, URLSessionDelegate {

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if let trust = challenge.protectionSpace.serverTrust {
            //print("[DEBUG] ✅ Accepting self-signed certificate for host: \(challenge.protectionSpace.host)")
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            //print("[DEBUG] BAD No serverTrust, default handling")
            Log.shared().print(page: "SSLBypassDelegate", fn: "urlSession", type: "ERROR", text: "No serverTrust, default handling")
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
