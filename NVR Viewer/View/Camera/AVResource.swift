//
//  AVResource.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/15/24.
//

import Foundation
import AVKit

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    /*
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource resourceLoadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        print("calling")
        if ((resourceLoadingRequest.request.url?.absoluteString.contains(".mp4"))!) {
            // replace the fakeScheme and get the original video url
            var originalVideoURLComps = URLComponents(url: resourceLoadingRequest.request.url!, resolvingAgainstBaseURL: false)!
            originalVideoURLComps.scheme = "file"
            let originalVideoURL = originalVideoURLComps.url
            
            var videoSize = 0
            do {
                let value = try originalVideoURL!.resourceValues(forKeys: [.fileSizeKey])
                videoSize = value.fileSize!
            } catch {
                print("error getting video size")
            }
            
            if (resourceLoadingRequest.contentInformationRequest != nil) {
                // this is the first request where we should tell the OS what file is to be downloaded
                let bytes : [UInt8] = [0x0, 0x0]    // TODO: repeat .requestedLength times?
                let data = Data(bytes: bytes, count: bytes.count)
                
                resourceLoadingRequest.contentInformationRequest?.contentType = AVFileType.mp4.rawValue // this is public.mpeg-4, video/mp4 does not work
                resourceLoadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
                resourceLoadingRequest.contentInformationRequest?.contentLength = Int64(videoSize)
                
                resourceLoadingRequest.dataRequest!.respond(with: data)
                resourceLoadingRequest.finishLoading()
                
                return true
            }
            
            // this is the second request where the actual file is to be downloaded
            
            let requestedLength = resourceLoadingRequest.dataRequest!.requestedLength
            let requestedOffset = resourceLoadingRequest.dataRequest!.requestedOffset
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: requestedLength)
            
            let inputStream = InputStream(url: originalVideoURL!)   // TODO: keep the stream open until a new file is requested?
            inputStream!.open()
            
            if (requestedOffset > 0) {
                // move the stream pointer to the requested position
                let buffer2 = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(requestedOffset))
                inputStream!.read(buffer2, maxLength: Int(requestedOffset)) // TODO: the requestedOffset may be int64, but this gets truncated to int!
                buffer2.deallocate()
            }
            inputStream!.read(buffer, maxLength: requestedLength)
            
            // decrypt the video
            if (requestedOffset == 0) { // TODO: this == 0 may not always work?
                // if you use custom encryption, you can decrypt the video here, buffer[] holds the bytes
            }
        
            let data = Data(bytes: buffer, count: requestedLength)
            
            resourceLoadingRequest.dataRequest?.respond(with: data)
            resourceLoadingRequest.finishLoading()
            
            buffer.deallocate()
            inputStream!.close()
            
            return true
        }
        
        return false
    }
    
    */
}

// extension APIRequester: URLSessionDelegate { }
