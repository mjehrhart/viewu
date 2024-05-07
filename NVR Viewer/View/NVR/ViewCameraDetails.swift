//
//  ViewCameraDetails.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 4/5/24.
//

import SwiftUI

struct ViewCameraDetails: View {
    
    var cameras: Cameras
    let text: String
    
    init (text: String, cameras: Cameras){
        self.cameras = cameras
        self.text = text
    }
    
    let widthMultiplier:CGFloat = 2/5.5
    
    var body: some View {
       
        Form{
            Section{
                HStack{
                    Text("Enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
            } header: {
                Text("Camera")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("Enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.audio.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                if(cameras.audio.enabled){
                    HStack{
                        Text("Enabled Config")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.audio.enabled_in_config)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Filters")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.audio.filters)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Listen")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .topLeading)
                            .padding(.leading, 40)
                        
                        HStack{
                            //ForEach(cameras.audio.listen, id: \.self) {item in
                            ScrollView(.horizontal){
                                Text("\(cameras.audio.listen)")
                                    .frame(width: .infinity, alignment: .leading)
                                    .foregroundStyle(.blue)
                            }
                            //}
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
            } header: {
                Text("Audio")
                    .font(.caption)
            }
            
            HStack{
                Text("Best Image Timeout")
                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                    .padding(.leading, 40)
                Text("\(cameras.best_image_timeout)")
                    .frame( alignment: .leading)
                    .foregroundStyle(.gray)
            }
            .frame(width: UIScreen.screenWidth, alignment: .leading)
            
            Section{
                HStack{
                    Text("Enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.birdseye.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                if(cameras.birdseye.enabled) {
                    HStack{
                        Text("Mode")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.birdseye.mode)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Order")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.birdseye.order)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
            } header: {
                Text("Birdseye")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("Enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.detect.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                if (cameras.detect.enabled) {
                    HStack{
                        Text("Annotation Offset")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.detect.annotation_offset)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("FPS")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.detect.fps)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Height")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(String(cameras.detect.height))")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Max Dissapeared")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.detect.max_disappeared)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Min Initialized")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.detect.min_initialized)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Width")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(String(cameras.detect.width))")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
            } header: {
                Text("Detect")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("Global Args")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    HStack{
                        ScrollView(.horizontal){
                            Text("\(cameras.ffmpeg.global_args)")
                                .frame(width: .infinity, alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                //                HStack{
                //                    Text("HwAccel Args")
                //                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                //                        .padding(.leading, 40)
                //                    VStack{
                //                        ForEach(cameras.ffmpeg.hwaccel_args, id: \.self) {item in
                //                            Text("\(item)")
                //                                .frame(width: 140, alignment: .leading)
                //                                .foregroundStyle(.gray)
                //                        }
                //                    }
                //                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Input Args")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.ffmpeg.input_args)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                VStack{
                    Text("Inputs")
                        .frame(width:UIScreen.screenWidth, alignment: .center)
                    //.padding(.leading, 40)
                    
                    VStack{
                        ForEach(cameras.ffmpeg.inputs, id: \.self) {item in
                            
                            HStack{
                                Text("Path")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                ScrollView(.horizontal){
                                    Text("\(item.path)")
                                        .frame(width: .infinity, alignment: .leading)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                            HStack{
                                Text("Global Args")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                ScrollView(.horizontal){
                                    Text("\(item.global_args)")
                                        .frame(width: .infinity, alignment: .leading)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                            
                            HStack{
                                Text("HwAccel Args")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                ScrollView(.horizontal){
                                    Text("\(item.hwaccel_args)")
                                        .frame(width: .infinity, alignment: .leading)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                            HStack{
                                Text("Input Args")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                ScrollView(.horizontal){
                                    Text("\(item.input_args)")
                                        .frame(width: .infinity, alignment: .leading)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                            HStack{
                                Text("Roles")
                                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                    .padding(.leading, 40)
                                ScrollView(.horizontal){
                                    Text("\(item.roles)")
                                        .frame(width: .infinity, alignment: .leading)
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(width: UIScreen.screenWidth, alignment: .leading)
                            
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                VStack{
                    Text("Output Args")
                        .frame(width:UIScreen.screenWidth, alignment: .center)
                    //.padding(.leading, 40)
                    
                    VStack{
                        HStack{
                            Text("Detect")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            ScrollView(.horizontal){
                                Text("\(cameras.ffmpeg.output_args.detect)")
                                    .frame( alignment: .leading)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        
                        HStack{
                            Text("Record")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            ScrollView(.horizontal){
                                Text("\(cameras.ffmpeg.output_args.record)")
                                    .frame( alignment: .leading)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        
                        HStack{
                            Text("RTMP")
                                .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                                .padding(.leading, 40)
                            ScrollView(.horizontal){
                                Text("\(cameras.ffmpeg.output_args.rtmp)")
                                    .frame( alignment: .leading)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    }
                    
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("retry_interval")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.ffmpeg.retry_interval)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("FFMEPG")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("Global Args")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    VStack{
                        ForEach(cameras.ffmpeg_cmds, id: \.self) {item in
                            ScrollView(.horizontal){
                                Text("\(item.cmd)")
                                    .frame(alignment: .leading)
                                    .foregroundStyle(.gray)
                                    .textSelection(.enabled)
                            }
                            ForEach(item.roles, id: \.self) {role in
                                ScrollView(.horizontal){
                                    Text("\(role)")
                                        .frame(width: .infinity, alignment: .leading)
                                        .foregroundStyle(.gray)
                                        .textSelection(.enabled)
                                }
                            }
                            
                        }
                        
                    }
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("FFMEPG Commands")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("Height")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.live.height)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Quality")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.live.quality)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Stream Name")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.live.stream_name)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Live")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("contour_area")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.contour_area)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("delta_alpha")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.delta_alpha)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("frame_alpha")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.frame_alpha)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("frame_height")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.frame_height)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("improve_contrast")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.improve_contrast)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("lightning_threshold")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.lightning_threshold)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("mask")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    ScrollView(.horizontal) {
                        Text("\(cameras.motion.mask)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("threshold")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.threshold)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("mqtt_off_delay")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.motion.mqtt_off_delay)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Motion")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.mqtt.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                if (cameras.mqtt.enabled) {
                    HStack{
                        Text("bounding_box")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.mqtt.bounding_box)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("crop")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.mqtt.crop)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("height")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.mqtt.height)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("quality")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.mqtt.quality)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("timestamp")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.mqtt.timestamp)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
            } header: {
                Text("MQTT")
                    .font(.caption)
            }
            
            HStack{
                Text("Name")
                    .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                    .padding(.leading, 40)
                Text("\(cameras.name)")
                    .frame( alignment: .leading)
                    .foregroundStyle(.gray)
            }
            .frame(width: UIScreen.screenWidth, alignment: .leading)
            
            Section{
                HStack{
                    Text("Objects")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    
                    ScrollView(.horizontal){
                        ForEach(Array(cameras.objects.filters.keys), id: \.self) {filter in
                            
                            //Text("Threshold: \(cameras.objects.filters[filter]?.threshold)")
                            Text("\(filter) Threshold: \(cameras.objects.filters[filter]?.threshold)")
                                .frame(width: 400, alignment: .leading)
                                .foregroundStyle(.gray)
                                .textSelection(.enabled)
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Objects")
                    .font(.caption)
            }
            
            Section{
                
                Text("autotracking")
                    .frame(width:UIScreen.screenWidth, alignment: .center)
                //.padding(.leading, 40)
                VStack{
                    HStack{
                        Text("Calibrate")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.calibrate_on_startup)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Enabled")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.enabled)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Config Enabled")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.enabled_in_config)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Return Preset")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.return_preset)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Timeout")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.timeout)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Zooming")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.zooming)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Zoom Factor")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.zoom_factor)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("Track")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal){
                            Text("\(cameras.onvif.autotracking.track)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("host")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.onvif.host)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("password")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.onvif.password)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("port")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.onvif.port)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("user")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.onvif.user)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Onvif")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.record.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                if(cameras.record.enabled){
                    HStack{
                        Text("enabled_in_config")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.record.enabled_in_config)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("events")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.record.events.pre_capture)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                        Text("\(cameras.record.events.post_capture)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                        //                    Text("\(cameras.record.events.retain)")
                        //                        .frame( alignment: .leading)
                        //                        .foregroundStyle(.gray)
                        Text("\(cameras.record.events.retain.mode)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("expire_interval")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.record.expire_interval)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("export")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        ScrollView(.horizontal) {
                            Text("\(cameras.record.export.timelapse_args)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("retain")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.record.retain.days)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                        Text("\(cameras.record.retain.mode)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("sync_recordings")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.record.sync_recordings)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
            } header: {
                Text("Record")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.rtmp.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Rtmp")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("enabled")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.snapshots.enabled)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                if (cameras.snapshots.enabled){
                    HStack{
                        Text("bounding_box")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.bounding_box)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("clean_copy")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.clean_copy)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("crop")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.crop)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("height")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.height)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("quality")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.quality)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("retain")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.retain.mode)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                    
                    HStack{
                        Text("timestamp")
                            .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                            .padding(.leading, 40)
                        Text("\(cameras.snapshots.timestamp)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: UIScreen.screenWidth, alignment: .leading)
                }
            } header: {
                Text("snapshots")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("color")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    
                    VStack{
                        HStack{
                            Text("Red")
                                .frame(width:50, alignment: .leading)
                                .foregroundStyle(.gray)
                            Text("\(cameras.timestamp_style.color.red)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        HStack{
                            Text("Blue")
                                .frame(width:50, alignment: .leading)
                                .foregroundStyle(.gray)
                            Text("\(cameras.timestamp_style.color.blue)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                        HStack{
                            Text("Green")
                                .frame(width:50, alignment: .leading)
                                .foregroundStyle(.gray)
                            Text("\(cameras.timestamp_style.color.green)")
                                .frame( alignment: .leading)
                                .foregroundStyle(.gray)
                        }
                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                    }
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("format")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    ScrollView(.horizontal) {
                        Text("\(cameras.timestamp_style.format)")
                            .frame( alignment: .leading)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("position")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.timestamp_style.position)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("thickness")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.timestamp_style.thickness)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Timestamp Style")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("dashboard")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.ui.dashboard)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("order")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.ui.order)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Ui")
                    .font(.caption)
            }
            
            Section{
                HStack{
                    Text("webui_url")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(cameras.webui_url)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.gray)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("Web URL")
                    .font(.caption)
            }
            
        }
        .navigationBarTitle(text, displayMode: .inline)
    }
}

//#Preview {
//    ViewCameraDetails()
//}
