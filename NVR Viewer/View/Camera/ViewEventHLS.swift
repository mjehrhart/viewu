import Foundation
import SwiftUI
import MobileVLCKit

class VLCPlayerModel: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    @Published var mediaPlayer = VLCMediaPlayer()

    override init() {
        super.init()
        let lib = VLCLibrary.shared()
        lib.debugLogging = true
        lib.debugLoggingLevel = 0
        lib.setHumanReadableName("ViewuApp", withHTTPUserAgent: "ViewuApp")
        mediaPlayer.delegate = self
    }

    func mediaPlayerStateChanged(_ notification: Notification!) {
        guard let player = notification.object as? VLCMediaPlayer else { return }
        print("VLC State Changed: \(player.state.rawValue) - \(player.state)")

        if player.state == .error {
            print("🔴 VLC ERROR — TLS handshake failed or other network error")
        } else if player.state == .playing {
            print("🟢 Playback started")
        }
    }

    func mediaPlayerEncounteredError(_ player: VLCMediaPlayer!) {
        print("🔴 VLC internal error callback")
        if let url = player.media?.url {
            print("⚠️ Failed URL: \(url.absoluteString)")
        }
    }
}

struct ViewEventHLS: View {
    // This will fail on iOS if the cert is not trusted
    let streamUrl: String =
        "https://192.168.1.152:8971/vod/event/1764993361.777595-gw7tcy/master.m3u8"

    @StateObject private var playerModel = VLCPlayerModel()

    var body: some View {
        VStack {
            VlcPlayerView(playerModel: playerModel)
                .aspectRatio(16/9, contentMode: .fit)
                .onAppear { configureAndPlay() }
                .onDisappear { playerModel.mediaPlayer.stop() }
        }
    }

    func configureAndPlay() {
        guard let url = URL(string: streamUrl) else { return }

        let media = VLCMedia(url: url)

        do {
            let token = try generateSyncJWT()
            print(token)
            media.addOption(":http-header=Authorization=Bearer \(token)")
            print("✅ Added Authorization header")
        } catch {
            print("❌ JWT error: \(error.localizedDescription)")
        }

        // SSL bypass options — note: they are **ignored by iOS** if cert is untrusted
        media.addOption(":no-http-ssl-verify")
        media.addOption(":no-https-verify")
        media.addOption(":no-ssl-verify")
        media.addOption(":no-http-ssl-certs")

        //media.addOption(":http-header=Authorization=Bearer \(token)")
        media.addOption(":http-header=Host=192.168.1.152")
        media.addOption(":http-header=User-Agent=ViewuApp/1.0")
        media.addOption(":network-caching=150")
        media.addOption(":demux=hls")
        media.addOption(":access=httplive")
        media.addOption(":verbose=2")
        
        // HLS options
        media.addOption(":network-caching=150")
        media.addOption(":demux=hls")
        media.addOption(":access=httplive")
        media.addOption(":verbose=2")

        playerModel.mediaPlayer.media = media
        playerModel.mediaPlayer.audio?.isMuted = true

        let ok = playerModel.mediaPlayer.play()
        print("mediaPlayer.play() returned: \(ok)")
    }
}

struct VlcPlayerView: UIViewRepresentable {
    @ObservedObject var playerModel: VLCPlayerModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        playerModel.mediaPlayer.drawable = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
