import Foundation
import SwiftUI
import AVFoundation

// MARK: - View

struct DownloadView: View {
    let urlString: String
    let fileName: Double   // Unix timestamp used in filename
    
    /// toggle to show/hide percentage + progress bar
    let showProgress: Bool

    @StateObject private var vm = DownloadViewModel()
    @State private var statusMessage: String = "Download Video"

    let cardShape = RoundedCornerShape(
        radius: 22,
        corners: [.bottomLeft, .bottomRight]
    )

    var body: some View {
        let isComplete = vm.progress == 1.0 && !vm.isDownloading
        let pillShape = BottomRoundedShape(radius: 10)

        HStack(spacing: 12) {

            // Leading icon badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: vm.isDownloading ? "arrow.down.circle.fill" :
                      (isComplete ? "checkmark.circle.fill" : "square.and.arrow.down"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        vm.isDownloading ? Color.white.opacity(0.9) :
                        (isComplete ? Color.green.opacity(0.9) : Color.white.opacity(0.9))
                    )
            }
            .frame(width: 34, height: 34)

            // Texts
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    vm.isDownloading ? "Downloading clip…" :
                    (isComplete ? "Download complete" : "Save clip")
                )
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

                Text(statusMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            // Right side: progress / spinner / chevron
            if vm.isDownloading {
                if showProgress {
                    if vm.progress > 0 {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("\(Int(vm.progress * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))

                            ProgressView(value: Double(vm.progress))
                                .progressViewStyle(.linear)
                                .frame(width: 80)
                        }
                    } else {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    }
                } else {
                    ProgressView()
                        .frame(width: 24, height: 24)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: 35)
        .background(
            pillShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    pillShape
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .opacity(vm.isDownloading ? 0.95 : 1.0)
        .onTapGesture {
            guard !vm.isDownloading else { return }

            if let url = URL(string: urlString) {
                statusMessage = "Downloading…"
                vm.downloadAndSaveVideo(
                    from: url,
                    fileName: "\(convertDateTime(time: fileName)).mp4"
                )
            } else {
                statusMessage = "Invalid URL."
            }
        }
        .onChange(of: vm.isDownloading) { newValue in
            if !newValue {
                if vm.progress == 1.0 {
                    statusMessage = "Saved to Files"
                } else if statusMessage == "Downloading…" {
                    statusMessage = "Download failed"
                }
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: vm.isDownloading)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: vm.progress)
    }

    // MARK: - Helpers

    private func convertDateTime(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = .current
        var localDate = dateFormatter.string(from: date)
        localDate.replace("at", with: "")
        return localDate
    }
}

#Preview {
    DownloadView(
        urlString: "https://middle.viewu.app/api/events/1764807972.940936-4ym9k8/clip.mp4",
        fileName: 631148400,
        showProgress: true
    )
}

// MARK: - ViewModel

@MainActor
class DownloadViewModel: NSObject,
                          ObservableObject,
                          URLSessionDownloadDelegate,
                          URLSessionDelegate {

    @Published var progress: Float = 0       // 0.0 ... 1.0
    @Published var isDownloading = false

    private var urlSession: URLSession!
    private var downloadCompletionHandlers: [URLSessionDownloadTask: (Result<URL, Error>) -> Void] = [:]
    private var downloadTaskFilenames: [URLSessionDownloadTask: String] = [:]

    enum DownloadError: Error, LocalizedError {
        case missingDownloadTask
        case fileIsEmpty
        case fileIsNotVideo
        case missingFilename
        case httpStatus(code: Int)

        var errorDescription: String? {
            switch self {
            case .missingDownloadTask:
                return "The download task could not be tracked."
            case .fileIsEmpty:
                return "The downloaded file was empty."
            case .fileIsNotVideo:
                return "The file appears corrupted or is not a valid video."
            case .missingFilename:
                return "Could not determine the required filename."
            case .httpStatus(let code):
                return "HTTP request failed with status code \(code)."
            }
        }
    }

    override init() {
        super.init()

        let config = URLSessionConfiguration.default
        // You can tweak additional config here if you need to.
        self.urlSession = URLSession(configuration: config,
                                     delegate: self,
                                     delegateQueue: nil)
    }

    // MARK: - Public API

    func downloadAndSaveVideo(from url: URL, fileName: String) {
        guard !isDownloading else { return }

        Task {
            await downloadAndSaveVideoInternal(from: url, fileName: fileName)
        }
    }

    func cancelDownload() {
        urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            downloadTasks.forEach { $0.cancel() }
        }
        DispatchQueue.main.async {
            self.isDownloading = false
            self.progress = 0
            self.downloadCompletionHandlers.removeAll()
            self.downloadTaskFilenames.removeAll()
        }
    }

    // MARK: - Internal download/save coordinator

    private func downloadAndSaveVideoInternal(from url: URL, fileName: String) async {
        isDownloading = true
        progress = 0

        do {
            let fileURL = try await downloadVideoDelegate(url: url, fileName: fileName)

            let asset = AVAsset(url: fileURL)
            guard !asset.tracks(withMediaType: .video).isEmpty else {
                Log.error(
                    page: "DownloadViewModel",
                    fn: "downloadAndSaveVideoInternal", "Downloaded file has no video tracks – likely an error page or invalid clip."
                )
                throw DownloadError.fileIsNotVideo
            }

            progress = 1.0

        } catch is CancellationError {
            Log.error(
                page: "DownloadViewModel",
                fn: "downloadAndSaveVideoInternal", "Download cancelled by user."
            )
            progress = 0
        } catch {
            Log.error(
                page: "DownloadViewModel",
                fn: "downloadAndSaveVideoInternal", "Download or save error: \(error.localizedDescription)"
            )
            progress = 0
        }

        isDownloading = false
    }

    // MARK: - Delegate-Based Download Function (Bridges to async/await and stores filename)

    private func downloadVideoDelegate(url: URL, fileName: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                var request = URLRequest(url: url)

                // Read AuthType from UserDefaults (same raw values as @AppStorage)
                let storedRawValue = UserDefaults.standard.string(forKey: "authType")
                    ?? AuthType.none.rawValue
                let authType = AuthType(rawValue: storedRawValue) ?? .none

                Log.error(
                    page: "DownloadViewModel",
                    fn: "downloadVideoDelegate", "Starting download. url=\(url.absoluteString), authType=\(authType), rawValue=\(storedRawValue)"
                )

                switch authType {
                case .none:
                    break

                case .bearer:
                    let token = try generateSyncJWTBearer()
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    Log.debug(
                        page: "DownloadViewModel",
                        fn: "downloadVideoDelegate", "Using bearer token for .bearer (Authorization header set)"
                    )

                case .frigate:
                    let token = try generateSyncJWTFrigate()
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    Log.debug(
                        page: "DownloadViewModel",
                        fn: "downloadVideoDelegate", "Using bearer token for .frigate (Authorization header set)"
                    )

                case .cloudflare:
                    let clientId = UserDefaults.standard.string(forKey: "cloudFlareClientId") ?? ""
                    let clientSecret = UserDefaults.standard.string(forKey: "cloudFlareSecret") ?? ""
                    request.setValue(clientId,     forHTTPHeaderField: "CF-Access-Client-Id")
                    request.setValue(clientSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
                    Log.debug(
                        page: "DownloadViewModel",
                        fn: "downloadVideoDelegate", "Using Cloudflare headers (id and secret set)"
                    )

                case .custom:
                    break
                }

                let task = urlSession.downloadTask(with: request)

                downloadCompletionHandlers[task] = { result in
                    switch result {
                    case .success(let url):
                        Log.debug(
                            page: "DownloadViewModel",
                            fn: "downloadVideoDelegate", "Download completion handler success: \(url.lastPathComponent)"
                        )
                        continuation.resume(returning: url)

                    case .failure(let error):
                        Log.error(
                            page: "DownloadViewModel",
                            fn: "downloadVideoDelegate", "Download completion handler failure: \(error.localizedDescription)"
                        )
                        continuation.resume(throwing: error)
                    }
                }

                downloadTaskFilenames[task] = fileName
                task.resume()

            } catch {
                Log.error(
                    page: "DownloadViewModel",
                    fn: "downloadVideoDelegate", "Failed to build request / token: \(error.localizedDescription)"
                )
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - URLSessionDelegate (trust LAN self-signed certs only)

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // Very intentional: only relax trust for LAN hosts (like 192.168.x.x).
        if isLanHost(host) {
            Log.debug(
                page: "DownloadViewModel",
                fn: "urlSession(didReceive:challenge:)", "Trusting self-signed certificate for LAN host: \(host)"
            )
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    /// Simple LAN host heuristic: adjust to match your environment if needed.
    private func isLanHost(_ host: String) -> Bool {
        if host == "localhost" || host == "127.0.0.1" {
            return true
        }

        // 192.168.x.x
        if host.hasPrefix("192.168.") { return true }

        // 10.x.x.x
        if host.hasPrefix("10.") { return true }

        // 172.16–31.x.x
        if host.hasPrefix("172.") {
            let parts = host.split(separator: ".")
            if parts.count >= 2, let second = Int(parts[1]), (16...31).contains(second) {
                return true
            }
        }

        return false
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL)
    {
        guard let completion = downloadCompletionHandlers.removeValue(forKey: downloadTask) else {
            Log.error(
                page: "DownloadViewModel",
                fn: "urlSession(didFinishDownloadingTo)", "ERROR: Download task completed but no completion handler was found."
            )
            return
        }

        do {
            let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? -1
            let urlString = downloadTask.originalRequest?.url?.absoluteString ?? "Unknown URL"

            Log.debug(
                page: "DownloadViewModel",
                fn: "urlSession(didFinishDownloadingTo)", "Finished download. statusCode=\(statusCode), url=\(urlString)"
            )

            if !(200...299).contains(statusCode) {
                Log.error(
                    page: "DownloadViewModel",
                    fn: "urlSession(didFinishDownloadingTo)", "Non-success HTTP statusCode=\(statusCode) for \(urlString)"
                )
                completion(.failure(DownloadError.httpStatus(code: statusCode)))
                return
            }

            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

            guard let destinationFileName = downloadTaskFilenames.removeValue(forKey: downloadTask) else {
                completion(.failure(DownloadError.missingFilename))
                return
            }

            let finalURL = documentsURL.appendingPathComponent(destinationFileName, isDirectory: false)

            if fileManager.fileExists(atPath: finalURL.path) {
                try fileManager.removeItem(at: finalURL)
            }

            try fileManager.moveItem(at: location, to: finalURL)

            Log.debug(
                page: "DownloadViewModel",
                fn: "urlSession(didFinishDownloadingTo)", "Saved file to \(finalURL.lastPathComponent)"
            )

            completion(.success(finalURL))

        } catch {
            Log.error(
                page: "DownloadViewModel",
                fn: "urlSession(didFinishDownloadingTo)", "File move error: \(error.localizedDescription)"
            )
            completion(.failure(error))
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard totalBytesExpectedToWrite > 0 else {
            return
        }

        let current = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        Task { @MainActor in
            self.progress = min(max(current, 0), 1)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?)
    {
        guard let downloadTask = task as? URLSessionDownloadTask else { return }

        if error != nil {
            downloadTaskFilenames.removeValue(forKey: downloadTask)
        }

        if let error = error {
            if let completion = downloadCompletionHandlers.removeValue(forKey: downloadTask) {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Shapes

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct BottomRoundedShape: Shape {
    var radius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct BottomRoundedRectangle: InsettableShape {
    var radius: CGFloat = 22
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        let bezier = UIBezierPath(
            roundedRect: insetRect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(bezier.cgPath)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

