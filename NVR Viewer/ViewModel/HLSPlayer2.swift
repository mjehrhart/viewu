

import SwiftUI
import WebKit

struct HLSPlayer2: View {

    let urlString: String
    let cameraName: String
    let menuTextColor = Color.white
    let cBlue = Color(red: 0.153, green: 0.69, blue: 1)

    @State var flagFull = false
    
    var isNotIPOnHTTPS: Bool {
            !isHttpsLanURL(urlString)
        }
 
    var message: String {
        if isHttpsLanURL(urlString) {
            return "Streaming may fail with self-signed certs on IP addresses. Apple explecitly blocks this for security reasons"
        } else {
            return "Live HLS stream"
        }
    }
 
    var body: some View {

         
            let pillShape = BottomRoundedRectangle(radius: 22)
            VStack(spacing: 0) {

                // MARK: HLS WebView (video area)
                ZStack {
                    // Soft grey/blue gradient background
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(red: 0.80, green: 0.80, blue: 0.80),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Webview(url: urlString + "/api/\(cameraName)?h=720")
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.75))
                        .clipped()
                }
                .frame(maxWidth: .infinity)

                // MARK: Bottom pill controls – same style as RTSP / Save Clip
                HStack(spacing: 12) {

                    // Left: icon + camera name
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.20))

                            Image(systemName: "video.badge.waveform")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cameraName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)

                            Text(message)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer()

                    // Right: fullscreen circle button
                    HStack(spacing: 10) {
                        Button {
                            flagFull.toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.60))

                                Image(systemName: "arrow.down.left.and.arrow.up.right.rectangle")
                                    .font(.system(size: 18, weight: .semibold))
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
                .clipShape(pillShape)
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
            .padding(.bottom, 15)
            .navigationDestination(isPresented: $flagFull) {
                ViewCameraHLSFullScreen(urlString: urlString, cameraName: cameraName)
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

// unchanged Webview
struct Webview: UIViewRepresentable {

    var url: String

    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: self.url) else {
            return WKWebView()
        }
        let request = URLRequest(url: url)
        let wkWebview = WKWebView()
        wkWebview.load(request)
        return wkWebview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


func isHttpsLanURL(_ urlString: String) -> Bool {
    // Parse URL safely
    guard
        let url = URL(string: urlString),
        let scheme = url.scheme?.lowercased(),
        scheme == "https",
        let host = url.host
    else {
        return false
    }
    
    // localhost counts as "LAN"
    if host == "localhost" || host == "127.0.0.1" {
        return true
    }
    
    // Try to parse as IPv4
    let parts = host.split(separator: ".")
    guard parts.count == 4,
          let o1 = Int(parts[0]),
          let o2 = Int(parts[1]),
          let o3 = Int(parts[2]),
          let o4 = Int(parts[3]),
          (0...255).contains(o1),
          (0...255).contains(o2),
          (0...255).contains(o3),
          (0...255).contains(o4)
    else {
        // Not a numeric IPv4 address -> we can’t be sure it’s LAN,
        // so treat as not-LAN.
        
        return false
    }
 
    
    // Check common private/LAN ranges
    switch (o1, o2) {
    case (10, _):                // 10.0.0.0 – 10.255.255.255
        return true
    case (172, 16...31):         // 172.16.0.0 – 172.31.255.255
        return true
    case (192, 168):             // 192.168.0.0 – 192.168.255.255
        return true
    case (169, 254):             // 169.254.x.x (link-local)
        return true
    default:
        return false
    }
}
