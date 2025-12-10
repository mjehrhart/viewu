//
//  ViewNVRDetails.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 4/1/24.
//

import SwiftUI

@MainActor
struct ViewNVRDetails: View {

    @EnvironmentObject private var notificationManager2: NotificationManager
    @ObservedObject private var config = NVRConfigurationSuper2.shared()

    private let widthMultiplier: CGFloat = 2 / 5

    // Use the dismiss action
    @Environment(\.dismiss) private var dismiss

    init() {}

    var body: some View {
        Form {
            // MARK: - Cameras
            Section {
                ForEach(config.item.cameras.keys.sorted(), id: \.self) { cameraName in
                    if let camera = config.item.cameras[cameraName] {
                        NavigationLink(cameraName, value: camera)
                            .foregroundStyle(.blue)
                    }
                }
            } header: {
                Text("Cameras")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // MARK: - MQTT
            Section {
                mqttRow(title: "ClientID", value: config.item.mqtt.client_id)
                mqttRow(title: "Host",     value: config.item.mqtt.host)
                mqttRow(title: "Port",     value: String(config.item.mqtt.port))
                mqttRow(title: "Topic",    value: config.item.mqtt.topic_prefix)
                mqttRow(title: "Interval2", value: String(config.item.mqtt.stats_interval))
            } header: {
                Text("MQTT")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            // MARK: - go2rtc Streams
            if let streams = config.item.go2rtc.streams {
                Section {
                    ForEach(streams.keys.sorted(), id: \.self) { key in
                        if !key.isEmpty, let urls = streams[key] {
                            Text(key)
                                .frame(width: UIScreen.screenWidth,
                                       alignment: .leading)
                                .padding(.leading, 75)

                            ForEach(urls, id: \.self) { item in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    Text(item)
                                        .textSelection(.enabled)
                                        .foregroundStyle(.secondary)
                                        .frame(width: UIScreen.screenWidth,
                                               alignment: .leading)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Go2RTC")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground)) // very light gray
        .toolbar(.hidden, for: .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    dismiss()                  // manually dismiss the view
                    notificationManager2.newPage = 0
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                }
                .foregroundStyle(.blue)
            }
        }
        .navigationTitle("NVR Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func mqttRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .frame(width: UIScreen.screenWidth * widthMultiplier,
                       alignment: .leading)
                .padding(.leading, 40)

            Text(value)
                .frame(alignment: .leading)
                .foregroundStyle(.secondary)
        }
        .frame(width: UIScreen.screenWidth, alignment: .leading)
    }
}

struct HorizontalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon.font(.system(size: 18, weight: .medium, design: .default))
            configuration.title.font(.system(size: 17))
        }
    }
}

// MARK: - Remove
/*
import SwiftUI

struct ViewNVRDetails: View {
    
    let nvr = NVRConfig.shared()
    
    @EnvironmentObject private var notificationManager2: NotificationManager
    //@ObservedObject var config = NVRConfigurationSuper.shared()
    @ObservedObject var config = NVRConfigurationSuper2.shared()
    
    let cNVR = APIRequester()
    //var sup = NVRConfigurationSuper()
    var sup = NVRConfigurationSuper2()
    let widthMultiplier:CGFloat = 2/5
    
    //Use the dismiss action
    @Environment(\.dismiss) var dismiss
    
    init(){
    }
    
    var body: some View {
          
        Form{
            Section{
                ForEach(Array(config.item.cameras.keys).enumerated().sorted(by: {$0 < $1} ), id: \.element) { index, camera in
                    NavigationLink("\(camera)", value: config.item.cameras[camera])
                        .foregroundStyle(.blue)
                }
            } header: {
                Text("Cameras")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Section{
                HStack{
                    Text("ClientID")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.client_id)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Host")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.host)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Port")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(String(config.item.mqtt.port))")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Topic")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.topic_prefix)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
                HStack{
                    Text("Interval2")
                        .frame(width:UIScreen.screenWidth*widthMultiplier, alignment: .leading)
                        .padding(.leading, 40)
                    Text("\(config.item.mqtt.stats_interval)")
                        .frame( alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .frame(width: UIScreen.screenWidth, alignment: .leading)
                
            } header: {
                Text("MQTT")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
          
            if ( config.item.go2rtc.streams != nil  ){ 
                //streams: ["" : [] ])
                Section {
                    ForEach(Array(config.item.go2rtc.streams!.keys ).sorted(by: {$0 < $1}), id: \.self) { value in
                      if !value.isEmpty {
                        Text("\(value)")
                            .frame(width:UIScreen.screenWidth, alignment: .leading)
                            .padding(.leading, 75)
  
                            ForEach(config.item.go2rtc.streams![value]!, id: \.self) { item in
                                ScrollView(.horizontal){
                                    Text("\(item)")
                                        .textSelection(.enabled)
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 0)
                                        .frame(width:UIScreen.screenWidth, alignment: .leading)
                                }
                            }
                        }
                   }
                } header: {
                    Text("Go2RTC")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
              
          
            
        }
        .background(Color(UIColor.secondarySystemBackground)) //very light gray
        .toolbar(.hidden, for: .bottomBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                
                Label("Back", systemImage: "chevron.backward")
                    .labelStyle(HorizontalLabelStyle())
                    .foregroundStyle(.blue)
                    .onTapGesture(perform: {
                        dismiss() // Manually dismiss the view
                        notificationManager2.newPage = 0
                    })
            }
        }
        .navigationBarTitle("NVR Configuration", displayMode: .inline)
        .navigationBarBackButtonHidden(true) 
    }
    
}

 

//#Preview {
//    ViewNVRDetails()
//}
*/
