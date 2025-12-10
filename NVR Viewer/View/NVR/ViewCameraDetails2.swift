//
//  ViewCameraDetails.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 11/8/25.
//

import SwiftUI

@MainActor
struct ViewCameraDetails2: View {

    let cameras: Cameras2
    let text: String

    private let widthMultiplier: CGFloat = 2 / 5.5

    init(text: String, cameras: Cameras2) {
        self.cameras = cameras
        self.text = text
    }

    var body: some View {
        Form {
            Section {
                detailRow(title: "Enabled", value: cameras.enabled ? "true" : "false")
            } header: {
                Text("Camera")
                    .font(.caption)
            } 
        }
        .navigationBarTitle(text, displayMode: .inline)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .frame(
                    width: UIScreen.screenWidth * widthMultiplier,
                    alignment: .leading
                )
                .padding(.leading, 40)

            Text(value)
                .frame(alignment: .leading)
                .foregroundStyle(.gray)
        }
        .frame(width: UIScreen.screenWidth, alignment: .leading)
    }
}
