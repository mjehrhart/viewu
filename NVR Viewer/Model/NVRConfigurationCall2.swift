//
//  NVRConfigurationCall2.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/8/25.
//

import Foundation

@MainActor
final class NVRConfigurationSuper2: ObservableObject { // Codable,
    
    let cNVR = APIRequester()
    @Published var item: NVRConfigurationCall2
    
    init() {
        item = NVRConfigurationCall2(
            version: "",
            record: RecordSettings2(
                detections: Detections2(
                    retain: RetainClips2(days: 10, mode: "")
                ),
                alerts: Alerts2(
                    retain: RetainClips2(days: 0, mode: "")
                )
            ),
            cameras: [
                "": Cameras2(
                    enabled: false,
                    ffmpeg: FFMPEG2(
                        inputs: [],
                        retry_interval: 0
                    ),
                    name: "",
                    objects: CameraObjects2(
                        filters: [
                            "": CameraFilters2(
                                max_area: 0,
                                max_ratio: 0,
                                min_area: 0,
                                min_ratio: 0,
                                min_score: 0.0,
                                threshold: 0.0
                            )
                        ]
                    ),
                    zones: [
                        "": Zone2(
                            inertia: 0,
                            loitering_time: 0
                        )
                    ], //color: [0]
                    snapshots: Snapshots2(
                        bounding_box: false,
                        clean_copy: false,
                        crop: false,
                        enabled: false,
                        height: 0,
                        quality: 0,
                        retain: SnapshotsRetain2(default: 0, mode: ""),
                        timestamp: false
                    )
                )
            ],
            mqtt: MQTT2(
                client_id: "String",
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
            go2rtc: Go2RTC2(
                streams: [
                    "": .many([""])
                ]
            )
        )
    }
    
    static let _shared = NVRConfigurationSuper2()
    static func shared() -> NVRConfigurationSuper2 {
        return _shared
    }
    
}

struct NVRConfigurationCall2: Codable, Hashable  {
    let version: String
    let record: RecordSettings2
    let cameras: [String: Cameras2]
    let mqtt: MQTT2
    let go2rtc: Go2RTC2                //?
}

struct RecordSettings2: Codable, Hashable {
    let detections: Detections2
    let alerts: Alerts2
}

struct Detections2: Codable, Hashable {
    let retain: RetainClips2
}

struct Alerts2: Codable, Hashable {
    let retain: RetainClips2
}

struct RetainClips2: Codable, Hashable {
    let days: Int
    let mode: String
}

//struct Go2RTC2: Codable, Hashable {
//    let streams: [String: [String]]?    //?
//}

enum StringOrArray: Codable, Hashable {
    case one(String)
    case many([String])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()

        if let s = try? c.decode(String.self) {
            self = .one(s)
            return
        }

        if let a = try? c.decode([String].self) {
            self = .many(a)
            return
        }

        throw DecodingError.typeMismatch(
            StringOrArray.self,
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Expected String or [String].")
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .one(let s):
            try c.encode(s)
        case .many(let a):
            try c.encode(a)
        }
    }

    /// Convenience if your app logic just wants arrays.
    var arrayValue: [String] {
        switch self {
        case .one(let s): return [s]
        case .many(let a): return a
        }
    }
}

struct Go2RTC2: Codable, Hashable {
    let streams: [String: StringOrArray]?
}

extension Go2RTC2 {
    static func from(_ dict: [String: [String]]) -> Go2RTC2 {
        .init(streams: dict.mapValues { .many($0) })
    }
}

struct Cameras2: Codable, Hashable {
    //let audio: Audio2
    //let best_image_timeout: Int
    //let birdseye: Birdseye2
    //let detect: Detect2
    let enabled: Bool
    let ffmpeg: FFMPEG2
    //let ffmpeg_cmds: [FFMPEGCommands2]
    //let live: Live2
    //let motion: Motion?
    //let mqtt: CameraMQTT2
    let name: String
    let objects: CameraObjects2
    //let onvif: ONVIF2
    //let record: Record2
    let zones: [String: Zone2]
    let snapshots: Snapshots2
    //let timestamp_style: TimeStampStyle2
    //let ui: CameraUI2
}

struct Zone2: Codable, Hashable {
    //let color: [Int?]
    let inertia: Int?
    let loitering_time: Int?
}

struct FFMPEG2: Codable, Hashable {
    //    let global_args: [String]
    //    let hwaccel_args: String
    //    let input_args: String
    let inputs: [CameraInputs2]
    //let output_args: CameraOutputArgs2
    let retry_interval: Int
}

struct CameraUI2: Codable, Hashable {
    let dashboard: Bool
    let order: Int
}

struct TimeStampStyle2: Codable, Hashable {
    let color: TimeStampStyleColor2
    //let effect: String? //Unknown Type
    let format: String
    let position: String
    let thickness: Int
}

struct TimeStampStyleColor2: Codable, Hashable {
    let blue: Int
    let green: Int
    let red: Int
}

struct Snapshots2: Codable, Hashable {
    let bounding_box: Bool
    let clean_copy: Bool
    let crop: Bool
    let enabled: Bool
    let height: Int?
    let quality: Int
    //let required_zones: [Unknown Type]
    let retain: SnapshotsRetain2
    let timestamp: Bool
}

struct SnapshotsRetain2: Codable, Hashable {
    let `default`: Float
    let mode: String
    //let objects: [String, Int]
}

struct Record2: Codable, Hashable {
    let enabled: Bool
    //let enabled_in_config: Bool?            // 6/2
    //let events: CameraEvents2
    let expire_interval: Int
    //let export: Export2
    let retain: RecordRetain2
    let sync_recordings: Bool
}

struct RecordRetain2: Codable, Hashable {
    let days: Double                //Int  6/2 changed from DOUBLE 11/8/25
    let mode: String
}

struct Export2: Codable, Hashable {
    let timelapse_args: String
}

struct CameraEvents2: Codable, Hashable {
    //let objects: [[String]]?
    let post_capture: Int
    let pre_capture: Int
    //let required_zones: [Unknown Type]
    let retain: Retain2
}

struct Retain2: Codable, Hashable {
    let `default`: Double               //Int  6/2
    let mode: String
    //let objects: [Unknown Type]
}

//TODO STRINGORARRAY - Not Used
struct AutoTracking2: Codable, Hashable {
    let calibrate_on_startup: Bool
    let enabled: Bool
    let enabled_in_config: Bool?        // 6/2
    //let movement_weights: [] not sure what type is
    //let required_zones: [] not sure what type is
    let return_preset: String
    let timeout: Int
    let track: [String]
    let zoom_factor: Double
    let zooming: String
}

struct ONVIF2: Codable, Hashable {
    let autotracking: AutoTracking2
    let host: String
    //let password: String?
    let port: Int64
    //let user: String?
}

struct CameraFilters2: Codable, Hashable {
    //let mask: Any,
    let max_area: Int               // should be Int 6/2
    let max_ratio: Double
    let min_area: Int               // should be Int 6/2
    let min_ratio: Double
    let min_score: Double
    let threshold: Double
}

struct CameraObjects2: Codable, Hashable {
    let filters: [String: CameraFilters2]
}

struct CameraMQTT2: Codable, Hashable {
    let bounding_box: Bool
    let crop: Bool
    let enabled: Bool
    let height: Int
    let quality: Int
    //let required_zones: [Any(something not sure what type this is)]
    let timestamp: Bool
}

struct Live2: Codable, Hashable {
    let height: Int
    let quality: Int
    //let streams: StreamName2
}

struct StreamName2: Codable, Hashable {
    let name: String
    //let value: String
}

//TODO STRINGORARRAY - Not Used
struct FFMPEGCommands2: Codable, Hashable {
    let cmd: String
    let roles: [String]
}

//TODO STRINGORARRAY - Used
struct CameraInputs2: Codable, Hashable {
    //let global_args: [String]
    //let hwaccel_args: [String]
    //let input_args: String
    let path: String
    //let roles: [String]
    let roles: StringOrArray
}

//TODO STRINGORARRAY - Not Used
struct CameraOutputArgs2: Codable, Hashable {
    let detect: [String]
    let record: String
}

struct Detect2: Codable, Hashable {
    let annotation_offset: Int
    let enabled: Bool
    let fps: Int
    let height: Int?                        //  6/2
    let max_disappeared: Int?               //  6/2
    //let min_initialized: Int?             //  6/2, .13 expects this to be a double
    let width: Int?                         //  6/2
    //let stationary: {} // new struct needed
}

struct Birdseye2: Codable, Hashable {
    let enabled: Bool
    let mode: String
    let order: Int
}

//TODO STRINGORARRAY - Not Used
struct Audio2: Codable, Hashable {
    let enabled: Bool
    let enabled_in_config: Bool?            // 6/2
    //let filters: String?
    let listen: [String]
    let max_not_heard: Int
    let min_volume: Int
    let num_threads: Int
}

/*
 struct Ui: Codable, Hashable  {
     let date_style: String
     let live_mode: String
     let time_format: String
     let time_style: String
     let use_experimental: Bool
 }
 */

struct MQTT2: Codable, Hashable {
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
 
