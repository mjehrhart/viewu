//
//  NVRConfigurationCall.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 4/1/24.
//

import Foundation

@MainActor
final class NVRConfigurationSuper: ObservableObject { // Codable,
    
    let cNVR = APIRequester()
    @Published var item: NVRConfigurationCall 
     
    init(){
        
        item = NVRConfigurationCall(
            cameras: ["" : Cameras(
                                   audio: Audio(enabled: false, enabled_in_config: false, filters: nil, listen: [], max_not_heard: 0, min_volume: 0, num_threads: 1 ),
                                   best_image_timeout: 0,
                                   birdseye: Birdseye(enabled: false, mode: "", order: 0),
                                   detect: Detect(annotation_offset: 0, enabled: false, fps: 5, height: 0, max_disappeared: 0, min_initialized: 0.0, width: 0),
                                   enabled: false, 
//                                   ffmpeg: FFMPEG(
//                                                  //global_args: [],
//                                                  //hwaccel_args: "", //is this a string or array
//                                                  input_args: "",
//                                                  inputs: [],
//                                                  output_args: CameraOutputArgs(detect: [], record: "" ), //, rtmp: ""
//                                                  retry_interval: 0 )
//                                   ,
                                   ffmpeg_cmds: [],
                                   live: Live(height: 0, quality: 0, stream_name: ""), 
                                   //motion: Motion(contour_area: 0, delta_alpha: 0.0, frame_alpha: 0.0, frame_height: 0, improve_contrast: false, lightning_threshold: 0.0, mask: [], mqtt_off_delay: 0, threshold: 0), 
                                   mqtt: CameraMQTT(bounding_box: false, crop: false, enabled: false, height: 0, quality: 0, timestamp: false),
                                   name: "",
                                   objects: CameraObjects(filters: ["": CameraFilters(max_area: 0, max_ratio: 0, min_area: 0, min_ratio: 0, min_score: 0.0, threshold: 0.0) ] ),
                                   onvif: ONVIF(autotracking: AutoTracking(calibrate_on_startup: false, enabled: false, enabled_in_config: false, return_preset: "", timeout: 0, track: [], zoom_factor: 0.0, zooming: ""),
                                                host: "", password: "", port: 1800, user: ""), 
                                   record: Record(enabled: false, enabled_in_config: false, events: CameraEvents(post_capture: 0, pre_capture: 0, retain: Retain(default: 0, mode: "")), expire_interval: 0, export: Export(timelapse_args: ""), retain: RecordRetain(days: 0, mode: ""), sync_recordings: false),
                                   //rtmp: RTMP(enabled: false),
                                   snapshots: Snapshots(bounding_box: false, clean_copy: false, crop: false, enabled: false, height: 0, quality: 0, retain: SnapshotsRetain(default: 0, mode: ""), timestamp: false),
                                   timestamp_style: TimeStampStyle(color: TimeStampStyleColor(blue: 0, green: 0, red: 0), format: "", position: "", thickness: 0),
                                   ui: CameraUI(dashboard: false, order: 0)
//                                   webui_url: ""
            )],
            mqtt: MQTT(client_id: "String",
                       enabled: false,
                       host: "String",
                       port: 1833,
                       stats_interval: 60,
                       topic_prefix: "frigate",
                       user: nil, 
                       tls_ca_certs: nil,
                       tls_client_cert: nil,
                       tls_client_key: nil,
                       tls_insecure: nil
                      ),
            go2rtc: Go2RTC(streams: ["" : [] ]))
    }
    
    static let _shared = NVRConfigurationSuper()
    static func shared() -> NVRConfigurationSuper {
        return _shared
    }
 
}

struct NVRConfigurationCall: Codable, Hashable  {
    let cameras: [String: Cameras]
    let mqtt : MQTT
    let go2rtc : Go2RTC
}

struct Cameras: Codable, Hashable {
    let audio: Audio
    let best_image_timeout: Int
    let birdseye: Birdseye
    let detect: Detect
    let enabled: Bool
    //let ffmpeg: FFMPEG
    let ffmpeg_cmds: [FFMPEGCommands]
    let live: Live
    //let motion: Motion
    let mqtt: CameraMQTT
    let name: String
    let objects: CameraObjects
    let onvif: ONVIF
    let record: Record
    //let rtmp: RTMP
    let snapshots: Snapshots
    let timestamp_style: TimeStampStyle
    let ui: CameraUI
//    let webui_url: String?
//    let zones: {} -> Unknown Type
}

struct FFMPEG: Codable, Hashable {
//    let global_args: [String]
//    let hwaccel_args: String
    let input_args: String
    let inputs: [CameraInputs]
    let output_args: CameraOutputArgs
    let retry_interval: Int
}

struct CameraUI: Codable, Hashable {
    let dashboard: Bool
    let order: Int
}

struct TimeStampStyle: Codable, Hashable {
    let color: TimeStampStyleColor
    //let effect: String? //Unknown Type
    let format: String
    let position: String
    let thickness: Int
}

struct TimeStampStyleColor: Codable, Hashable {
    let blue: Int
    let green: Int
    let red: Int
}

struct Snapshots: Codable, Hashable {
    let bounding_box: Bool
    let clean_copy: Bool
    let crop: Bool
    let enabled: Bool
    let height: Int?
    let quality: Int
    //let required_zones: [Unknown Type]
    let retain: SnapshotsRetain
    let timestamp: Bool
}
struct SnapshotsRetain: Codable, Hashable {
    let `default`: Int
    let mode: String
    //let objects: {} Unknown Type
}

struct RTMP: Codable, Hashable {
    let enabled: Bool
}

struct Record: Codable, Hashable {
    let enabled: Bool
    let enabled_in_config: Bool
    let events: CameraEvents
    let expire_interval: Int
    let export: Export
    let retain: RecordRetain
    let sync_recordings: Bool
}

struct RecordRetain: Codable, Hashable {
    let days: Int
    let mode: String
}

struct Export: Codable, Hashable {
    let timelapse_args: String
}

struct CameraEvents: Codable, Hashable {
    //let objects: Unknown type
    let post_capture: Int
    let pre_capture: Int
    //let required_zones: [Unknown Type]
    let retain: Retain
}

struct Retain: Codable, Hashable {
    let `default`: Int    // -> default is a keyword. //TODO
    let mode: String
    //let objects: [Unknown Type]
}

struct AutoTracking: Codable, Hashable {
    let calibrate_on_startup: Bool
    let enabled: Bool
    let enabled_in_config: Bool
    //let movement_weights: [] not sure what type is
    //let required_zones: [] not sure what type is
    let return_preset: String
    let timeout: Int
    let track: [String]
    let zoom_factor: Double
    let zooming: String
}

struct ONVIF: Codable, Hashable {
    let autotracking : AutoTracking
    let host: String
    let password: String?
    let port: Int64
    let user: String?
}

struct CameraFilters: Codable, Hashable{
    //let mask: Any,
    let max_area: Int64
    let max_ratio: Int64
    let min_area: Int
    let min_ratio: Int
    let min_score: Double
    let threshold: Double
}
 
struct CameraObjects: Codable, Hashable {
    let filters: [String: CameraFilters]
}

struct CameraMQTT: Codable, Hashable {
    let bounding_box: Bool
    let crop: Bool
    let enabled: Bool
    let height: Int
    let quality: Int
    //let required_zones: [Any(something not sure what type this is)]
    let timestamp: Bool
}
struct Motion: Codable, Hashable {
    let contour_area: Int
    let delta_alpha: Double
    let frame_alpha: Double
    let frame_height: Int
    let improve_contrast: Bool
    let lightning_threshold: Double
    let mask: [String]
    let mqtt_off_delay: Int
    let threshold: Int
}
struct Live: Codable, Hashable {
    let height: Int
    let quality: Int
    let stream_name: String
}

struct FFMPEGCommands: Codable, Hashable{
    let cmd: String
    let roles: [String]
}
  
struct CameraInputs: Codable, Hashable {
    //let global_args: [String]
    //let hwaccel_args: [String]
    //let input_args: String
    let path: String
    let roles: [String]
}

struct CameraOutputArgs: Codable, Hashable {
    let detect: [String]
    let record: String
    //let rtmp: String?
}

struct Detect: Codable, Hashable {
    let annotation_offset: Int
    let enabled: Bool
    let fps: Int
    let height: Int
    let max_disappeared: Int
    let min_initialized: Double
    let width: Int
    //let stationary: {} // new struct needed
}

struct Birdseye: Codable, Hashable{
    let enabled: Bool
    let mode: String
    let order: Int
}

struct Audio: Codable, Hashable {
    let enabled: Bool
    let enabled_in_config: Bool
    let filters: String?
    let listen: [String]
    let max_not_heard: Int
    let min_volume: Int
    let num_threads: Int
}
struct Ui: Codable, Hashable  {
    let date_style: String
    let live_mode: String
    let time_format: String
    let time_style: String
    let use_experimental: Bool
}

struct Go2RTC: Codable, Hashable {
    let streams: [String: [String]]
}
 
struct MQTT: Codable, Hashable {
    let client_id: String
    let enabled: Bool
    let host: String
    let port: Int64
    let stats_interval: Int
    let topic_prefix: String
    let user: String?
    let tls_ca_certs: String?
    let tls_client_cert: String?
    let tls_client_key: String?
    let tls_insecure: String?
}
 

