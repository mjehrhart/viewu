//
//  APIBuilder.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation

struct APIBuilder {
    
    // MARK: - Properties
    
    var dataSet: TopicFrigateEventHeader
    private let nvr: NVRConfig
    
    init(dataSet: TopicFrigateEventHeader, nvr: NVRConfig = .shared()) {
        self.dataSet = dataSet
        self.nvr = nvr
    }
    
    // Convenience accessors so we don't repeat the long paths everywhere
    private var eventID: String {
        dataSet.after.id
    }
    
    private var eventCamera: String {
        dataSet.after.camera
    }
    
    private var frameTime: Double {
        dataSet.after.frame_time
    }
    
    // MARK: - URL building
    
    private func buildAPIURL(endpoint: FrigateAPIEndpoint) -> String {
        let baseURL = nvr.getUrl()
        let id = eventID
        let camera = eventCamera
        let frameTime = frameTime
        
        switch endpoint {
        case .Thumbnail:
            return "\(baseURL)/api/events/\(id)/thumbnail.jpg"
        case .Snapshot:
            return "\(baseURL)/api/events/\(id)/snapshot.jpg"
        case .Image:
            return "\(baseURL)/api/\(camera)/recordings/\(frameTime)/snapshot.png"
        case .M3U8:
            return "\(baseURL)/vod/event/\(id)/master.m3u8"
        case .MP4:
            return "\(baseURL)/api/events/\(id)/clip.mp4"
        case .Camera:
            return "\(baseURL)/cameras/\(camera)"
        case .Debug:
            return "\(baseURL)/api/\(camera)?h=480"
        }
    }
    
    // MARK: - Metadata helpers
    
    /// Returns key metadata from a given event.
    func getEventKeyMetaData(
        fevent: TopicFrigateEventHeader
    ) -> (camera: String, frameTime: Double, score: Double, type: String) {
        (
            fevent.after.camera,
            fevent.after.frame_time,
            fevent.after.score,
            fevent.type
        )
    }
    
    /// Convenience overload using the stored `dataSet` (optional, but handy).
    func getEventKeyMetaData() -> (camera: String, frameTime: Double, score: Double, type: String) {
        getEventKeyMetaData(fevent: dataSet)
    }
    
    // MARK: - EndpointOptions builder
    
    func getAllEndpoint() -> EndpointOptions {
        var endpointOptions = EndpointOptions()
        
        endpointOptions.thumbnail = buildAPIURL(endpoint: .Thumbnail)
        endpointOptions.snapshot  = buildAPIURL(endpoint: .Snapshot)
        endpointOptions.m3u8      = buildAPIURL(endpoint: .M3U8)
        endpointOptions.mp4       = buildAPIURL(endpoint: .MP4)
        endpointOptions.camera    = buildAPIURL(endpoint: .Camera)
        endpointOptions.debug     = buildAPIURL(endpoint: .Debug)
        endpointOptions.image     = buildAPIURL(endpoint: .Image)
        
        // Meta Data for the endpoints
        endpointOptions.id         = dataSet.after.id
        endpointOptions.cameraName = dataSet.after.camera
        endpointOptions.type       = dataSet.type
        endpointOptions.frameTime  = dataSet.after.frame_time
        endpointOptions.score      = dataSet.after.top_score   // 12/7/25 was .score
        endpointOptions.label      = dataSet.after.label
        endpointOptions.sublabel   = dataSet.after.sub_label
        
        endpointOptions.currentZones = dataSet.after.current_zones
        endpointOptions.enteredZones = dataSet.after.entered_zones
        
        return endpointOptions
    }
    
    // MARK: - Network helper
    
    private func getDataFrom(url urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else {
            Log.shared().print(
                page: "APIBuilder",
                fn: "getDataFrom",
                type: "ERROR",
                text: "Invalid URL: \(urlString)"
            )
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                Log.shared().print(
                    page: "APIBuilder",
                    fn: "getDataFrom",
                    type: "ERROR",
                    text: "HTTP \(http.statusCode) for \(url.absoluteString)"
                )
                return nil
            }
            
            return data
        } catch {
            Log.shared().print(
                page: "APIBuilder",
                fn: "getDataFrom",
                type: "ERROR",
                text: error.localizedDescription
            )
            return nil
        }
    }
}

// MARK: - Remove
////
////  APIBuilder.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/1/24.
////
//
//import Foundation
//
//struct APIBuilder {
//    
//    var dataSet: TopicFrigateEventHeader
//    let nvr = NVRConfig.shared()
//    
//    private func getEventID(fevent: TopicFrigateEventHeader) -> String {
//        return fevent.after.id
//    }
//    
//    private func getEventCamera(fevent: TopicFrigateEventHeader) -> String {
//        return fevent.after.camera
//    }
//    
//    private func buildAPIURL(endpoint: FrigateAPIEndpoint, camera: String? = nil) -> String{
//        
//        let url = nvr.getUrl()
//        let id = getEventID(fevent: dataSet)
//        let camera = getEventCamera(fevent: dataSet)
//        let frameTime = dataSet.after.frame_time
//        
//        switch endpoint{
//        case .Thumbnail:
//            return url + "/api/events/\(id)/thumbnail.jpg"
//        case .Snapshot:
//            return url + "/api/events/\(id)/snapshot.jpg" //?bbox=1"
//        case .Image:
//            return url + "/api/\(camera)/recordings/\(frameTime)/snapshot.png"
//        case .M3U8:
//            return url + "/vod/event/\(id)/master.m3u8"
//        case .MP4:
//            return url + "/api/events/\(id)/clip.mp4"
//        case .Camera:
//            return url + "/cameras/\(camera)"
//        case .Debug:
//            return url + "/api/\(camera)?h=480"
//        }
//    }
//    
//    func getEventKeyMetaData(fevent: TopicFrigateEventHeader) -> (camera: String, frameTime: Double, score: Double, type: String) {
//        
//        return( fevent.after.camera, fevent.after.frame_time, fevent.after.score, fevent.type)
//    }
//    
//    func getAllEndpoint() -> EndpointOptions{
//        var endpointOptions = EndpointOptions()
//        endpointOptions.thumbnail = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Thumbnail)
//        endpointOptions.snapshot = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Snapshot)
//        endpointOptions.m3u8 = self.buildAPIURL(endpoint: FrigateAPIEndpoint.M3U8)
//        endpointOptions.mp4 = self.buildAPIURL(endpoint: FrigateAPIEndpoint.MP4)
//        endpointOptions.camera = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Camera)
//        endpointOptions.debug = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Debug)
//        endpointOptions.image = self.buildAPIURL(endpoint:  .Image)
//        
//        //Meta Data for the endpoints
//        endpointOptions.id = dataSet.after.id
//        endpointOptions.cameraName = dataSet.after.camera
//        endpointOptions.type = dataSet.type
//        endpointOptions.frameTime = dataSet.after.frame_time
//        endpointOptions.score = dataSet.after.top_score //12/7/25 was .score
//        endpointOptions.label = dataSet.after.label
//        endpointOptions.sublabel = dataSet.after.sub_label
//         
//        endpointOptions.currentZones = dataSet.after.current_zones
//        endpointOptions.enteredZones = dataSet.after.entered_zones
//        
//        return endpointOptions
//    }
//    
//    private func getDataFrom(url: String) async -> Data? {
//        do {
//            let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
//            return data
//        } catch {
//            Log.shared().print(page: "APIBuilder", fn: "getDataFrom", type: "ERROR", text: "")
//            return nil
//        }
//    }
//}
