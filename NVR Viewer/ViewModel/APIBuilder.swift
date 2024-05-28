//
//  APIBuilder.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import Foundation

struct APIBuilder {
    
    var dataSet: TopicFrigateEventHeader
    let nvr = NVRConfig.shared()
    
    private func getEventID(fevent: TopicFrigateEventHeader) -> String {
        return fevent.after.id
    }
    
    private func getEventCamera(fevent: TopicFrigateEventHeader) -> String {
        return fevent.after.camera
    }
    
    private func buildAPIURL(endpoint: FrigateAPIEndpoint, camera: String? = nil) -> String{
        
        let url = nvr.getUrl()
        let id = getEventID(fevent: dataSet)
        let camera = getEventCamera(fevent: dataSet)
        let frameTime = dataSet.after.frame_time
        
        switch endpoint{
        case .Thumbnail:
            return url + "/api/events/\(id)/thumbnail.jpg"
        case .Snapshot:
            return url + "/api/events/\(id)/snapshot.jpg?bbox=1"
        case .Image:
            return url + "/api/\(camera)/recordings/\(frameTime)/snapshot.png"
        case .M3U8:
            return url + "/vod/event/\(id)/master.m3u8"
        case .Camera:
            return url + "/cameras/\(camera)"
        case .Debug:
            return url + "/api/\(camera)?h=480"
        }
    }
    
    func getEventKeyMetaData(fevent: TopicFrigateEventHeader) -> (camera: String, frameTime: Double, score: Double, type: String) {
        
        return( fevent.after.camera, fevent.after.frame_time, fevent.after.score, fevent.type)
    }
    
    func getAllEndpoint() -> EndpointOptions{
        var endpointOptions = EndpointOptions()
        endpointOptions.thumbnail = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Thumbnail)
        endpointOptions.snapshot = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Snapshot)
        endpointOptions.m3u8 = self.buildAPIURL(endpoint: FrigateAPIEndpoint.M3U8)
        endpointOptions.camera = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Camera)
        endpointOptions.debug = self.buildAPIURL(endpoint: FrigateAPIEndpoint.Debug)
        endpointOptions.image = self.buildAPIURL(endpoint:  .Image)
        
        //Meta Data for the endpoints
        endpointOptions.id = dataSet.after.id
        endpointOptions.cameraName = dataSet.after.camera
        endpointOptions.type = dataSet.type
        endpointOptions.frameTime = dataSet.after.frame_time
        endpointOptions.score = dataSet.after.score
        endpointOptions.label = dataSet.after.label
        endpointOptions.sublabel = dataSet.after.sub_label
        
        print("------------------  func getAllEndpoint() -----------------------")
        print(dataSet.after.current_zones)
        print(dataSet.after.entered_zones)
        
        endpointOptions.currentZones = dataSet.after.current_zones
        endpointOptions.enteredZones = dataSet.after.entered_zones
        
        return endpointOptions
    }
    
    private func getDataFrom(url: String) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
            return data
        } catch {
            print("Error fetching data: \(error)")
            return nil
        }
    }
}
