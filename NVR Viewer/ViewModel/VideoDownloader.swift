import Foundation
import SwiftUI
import AVFoundation

@MainActor
class DownloadViewModel: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Float = 0
    @Published var isDownloading = false
    @Published var isDownloadStarted = false
    
    private var urlSession: URLSession!
    // Dictionary mapping tasks to their completion handlers
    private var downloadCompletionHandlers: [URLSessionDownloadTask: (Result<URL, Error>) -> Void] = [:]
    // Dictionary mapping tasks to their desired filenames
    private var downloadTaskFilenames: [URLSessionDownloadTask: String] = [:]
    
    enum DownloadError: Error, LocalizedError {
        case missingDownloadTask
        case fileIsEmpty
        case fileIsNotVideo
        case missingFilename
        
        var errorDescription: String? {
            switch self {
            case .missingDownloadTask: return "The download task could not be tracked."
            case .fileIsEmpty: return "The downloaded file was empty."
            case .fileIsNotVideo: return "The file appears corrupted or is not a valid video."
            case .missingFilename: return "Could not determine the required filename."
            }
        }
    }
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public API (Accepts the desired filename)
    func downloadAndSaveVideo(from url: URL, fileName: String) {
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
            self.isDownloadStarted = true
            self.progress = 0
            self.downloadCompletionHandlers.removeAll()
            self.downloadTaskFilenames.removeAll()
        }
    }
    
    // MARK: - Internal download/save coordinator
    private func downloadAndSaveVideoInternal(from url: URL, fileName: String) async {
        isDownloading = true
        isDownloadStarted = true
        progress = 0
        
        do {
            // Pass the fileName to the delegate bridge
            let fileURL = try await downloadVideoDelegate(url: url, fileName: fileName)
            print("Downloaded file at: \(fileURL.lastPathComponent)")
            
            // (Validation steps remain valid)
            let asset = AVAsset(url: fileURL)
            guard !asset.tracks(withMediaType: .video).isEmpty else {
                throw DownloadError.fileIsNotVideo
            }
            
            print("Video saved successfully to Documents Directory.")
            progress = 100
        } catch is CancellationError {
            print("Download cancelled by user.")
        } catch {
            print("Download or save error:", error.localizedDescription)
        }
        
        isDownloading = false
    }
    
    // MARK: - Delegate-Based Download Function (Bridges to async/await and stores filename)
    private func downloadVideoDelegate(url: URL, fileName: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.downloadTask(with: url)
            
            downloadCompletionHandlers[task] = { result in
                switch result {
                case .success(let url): continuation.resume(returning: url)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
            // Store the filename separately
            downloadTaskFilenames[task] = fileName
            
            task.resume()
        }
    }
    
    // MARK: - URLSessionDownloadDelegate Callbacks (Run on background thread)
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let completion = downloadCompletionHandlers.removeValue(forKey: downloadTask) else {
            print("ERROR: Download task completed but no completion handler was found.")
            return
        }
        
        do {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // --- Use the specific filename we stored earlier ---
            guard let destinationFileName = downloadTaskFilenames.removeValue(forKey: downloadTask) else {
                completion(.failure(DownloadError.missingFilename))
                return
            }
            
            let finalURL = documentsURL.appendingPathComponent(destinationFileName, isDirectory: false)
            // -----------------------------------------------------------
            
            if fileManager.fileExists(atPath: finalURL.path) {
                try fileManager.removeItem(at: finalURL)
            }
            
            try fileManager.moveItem(at: location, to: finalURL)
            
            completion(.success(finalURL))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let currentProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        // MainActor ensures this updates the UI correctly
        
        self.progress = convertToMeaningfulValue(progress: currentProgress)
    }
    
    func convertToMeaningfulValue(progress: Float) -> Float{
        
        let num: Float = progress
        var integerPart = Int(num)
        if (integerPart<0){
            integerPart = integerPart * -1
        }
        
        if integerPart >= 12 {
                let tip = integerPart / Int(pow(10, Double(String(integerPart).count - 3)))
            return Float(tip)
        } else if integerPart >= 0 {
            return 0.0
        } else {
            return 0.0
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask else { return }
        
        // Ensure we clean up tracking dictionaries if the task fails
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


//---------------------------------------------------------------------------------

// A SwiftUI View to run the code

struct DownloadView: View {
    let urlString: String
    let fileName: Double
    
    @StateObject private var vm = DownloadViewModel()
    @State private var statusMessage: String = "Download Video"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                
                GeometryReader { geometry in
                    if vm.isDownloading || vm.isDownloadStarted  {
                        HStack{
                            ProgressView("", value: (vm.progress ))
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding()
                            Text(String(format: "%.0f%%", vm.progress ))
                                .font(.system(size: 22))
                                .fontWeight(.regular)
                                .foregroundStyle(.white)
                        }
                        .frame(width:  geometry.size.width, height: 40, alignment: .leading)
                    } else {
                        HStack{
                            Label("", systemImage: "square.and.arrow.down") 
                                .foregroundStyle(.white)
                                .font(.system(size: 24))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .onTapGesture {
                                    Task {
                                        if vm.isDownloading {
                                            vm.cancelDownload()
                                            statusMessage = "Download Cancelled."
                                        } else {
                                            
                                            if let url = URL(string: urlString) {
                                                //statusMessage = "downloading..."
                                                // Provide the desired filename here
                                                vm.downloadAndSaveVideo(from: url, fileName: "\(convertDateTime(time: fileName)).mp4" )
                                            } else {
                                                statusMessage = "Invalid URL."
                                            }
                                        }
                                    }
                                }
                        }
                        .frame(width: geometry.size.width, height: 30, alignment: .trailing)
                        //.background(.orange)
                    }
                }
            }
            .frame(height: 30, alignment: .leading)
        }
        .frame( height: 30, alignment: .leading)
        .padding()
        .onChange(of: vm.isDownloading) { newValue in
            if !newValue && vm.progress == 1.0 {
                //statusMessage = ""
            } else if !newValue && vm.progress == 0.0 && statusMessage != "Download Cancelled." && statusMessage != "Invalid URL." {
                //statusMessage = ""
            }
        }
    }
    
    private func convertDateTime(time: Double) -> String{
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeZone = .current
        var localDate = dateFormatter.string(from: date)
        localDate.replace("at", with: "")
        return localDate
    }
}

#Preview {
    
    DownloadView(urlString: "https://middle.viewu.app/api/events/1764807972.940936-4ym9k8/clip.mp4", fileName: 631148400)
}
