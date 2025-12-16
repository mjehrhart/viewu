//
//  PopUpSync.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/15/25.
//

import SwiftUI
//import PopupView 

// MARK: - Popup Overlay (modern)

struct PopupMiddle: View {

    var onClose: () -> Void

    private var brandBlue: Color {
        if let ui = UIColor(named: "ViewuBlue") {
            return Color(uiColor: ui)
        }
        return Color(red: 0.20, green: 0.67, blue: 1.00)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 14) {

                // Update "ViewuLogo" to your actual asset name.
                Image("viewuLogoTransparent")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(brandBlue)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)

                Text("Syncing with Viewu Server")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("Your notification settings have been updated.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ProgressView()

                Text("Tap anywhere to dismiss")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(22)
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(brandBlue.opacity(0.22), lineWidth: 1)
            )
            .padding(.horizontal, 18)
        }
        .onTapGesture { onClose() }
    }
}
