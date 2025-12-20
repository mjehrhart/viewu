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
                        if !key.isEmpty {
                            let urls = streams[key]?.arrayValue ?? []
                            if !urls.isEmpty {
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
                    }
                } header: {
                    Text("Go2RTC")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

//            if let streams = config.item.go2rtc.streams {
//                Section {
//                    ForEach(streams.keys.sorted(), id: \.self) { key in
//                        if !key.isEmpty, let urls = streams[key] {
//                            Text(key)
//                                .frame(width: UIScreen.screenWidth,
//                                       alignment: .leading)
//                                .padding(.leading, 75)
//
//                            ForEach(urls, id: \.self) { item in
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    Text(item)
//                                        .textSelection(.enabled)
//                                        .foregroundStyle(.secondary)
//                                        .frame(width: UIScreen.screenWidth,
//                                               alignment: .leading)
//                                }
//                            }
//                        }
//                    }
//                } header: {
//                    Text("Go2RTC")
//                        .font(.caption)
//                        .foregroundColor(.orange)
//                }
//            }
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
