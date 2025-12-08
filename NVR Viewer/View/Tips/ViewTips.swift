//
//  ViewTips.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/16/25.
//

import SwiftUI
 
struct TipsInfoBanner: View {
    @Binding var isVisible: Bool
    let title: String
    let message: String
    let collapsedLabel: String
    let iconColor: Color

    var body: some View {
        Group {
            if isVisible {
                HStack(alignment: .top, spacing: 8) {
                    // Left icon
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)

                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .textCase(nil)

                        Text(message)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    // Close button
                    Button {
                        isVisible = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(iconColor.opacity(0.08))   // nice blue tint
                .cornerRadius(12)
            } else {
                // Collapsed “show tips” row
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text(collapsedLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
                .padding(6)
                .contentShape(Rectangle())
                .onTapGesture {
                    isVisible = true
                }
            }
        }
    }
}

struct ViewTipsNotificationManager: View {
    @AppStorage("tipsNotificationDefault") private var tipsNotificationDefault: Bool = true

    let title: String
    let message: String
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)

    var body: some View {
        TipsInfoBanner(
            isVisible: $tipsNotificationDefault,
            title: title,
            message: message,
            collapsedLabel: "Show Notification Manager info",
            iconColor: iconColor
        )
    }
}

struct ViewTipsNotificationDomain: View {
    @AppStorage("tipsNotificationDomain") private var tipsNotificationDomain: Bool = true

    let title: String
    let message: String
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)

    var body: some View {
        TipsInfoBanner(
            isVisible: $tipsNotificationDomain,
            title: title,
            message: message,
            collapsedLabel: "Show Accessible Domain info",
            iconColor: iconColor
        )
    }
}

struct ViewTipsNotificationTemplate: View {
    @AppStorage("tipsNotificationTemplate") private var tipsNotificationTemplate: Bool = true

    let title: String
    let message: String
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)

    var body: some View {
        TipsInfoBanner(
            isVisible: $tipsNotificationTemplate,
            title: title,
            message: message,
            collapsedLabel: "Show Notification Templates info",
            iconColor: iconColor
        )
    }
}

struct ViewTipsSettingsNVR: View {
    @AppStorage("tipsSettingsNVR") private var tipsSettingsNVR: Bool = true

    let title: String
    let message: String
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)

    var body: some View {
        TipsInfoBanner(
            isVisible: $tipsSettingsNVR,
            title: title,
            message: message,
            collapsedLabel: "Show NVR settings info",
            iconColor: iconColor
        )
    }
}

struct ViewTipsSettingsPairDevie: View {
    @AppStorage("tipsSettingsPairDevice") private var tipsSettingsPairDevice: Bool = true

    let title: String
    let message: String
    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)

    var body: some View {
        TipsInfoBanner(
            isVisible: $tipsSettingsPairDevice,
            title: title,
            message: message,
            collapsedLabel: "Show device pairing info",
            iconColor: iconColor
        )
    }
}

struct ViewTipsLiveCameras: View {
    @AppStorage("tipsLiveCameras") private var tipsLiveCameras: Bool = true

    let title: String
    let message: String

    let iconColor: Color = Color(red: 0.153, green: 0.69, blue: 1)

    init(title: String, message: String ) {
        self.title = title
        self.message = message
    }

    var body: some View {
        Group {
            if tipsLiveCameras {
                HStack(alignment: .top, spacing: 8) {
                    // Left icon
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)

                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))

                        Text(message)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    // Close button
                    Button {
                        tipsLiveCameras = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
            } else {
                // Collapsed state with small “show tips” affordance
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text("Show live camera tips")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(6)
                .contentShape(Rectangle())
                .onTapGesture {
                    tipsLiveCameras = true
                }
            }
        }
    }
}

