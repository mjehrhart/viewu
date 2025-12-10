//
//  ViewEventList.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//
 
import SwiftUI

@MainActor
struct ViewEventListHome: View {

    // Background Tasks (currently just a hook)
    @Environment(\.scenePhase) private var scenePhase

    init() {}

    var body: some View {
        VStack {
            ViewEventList(title: "Event Timeline")
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Hook for future behavior if needed
            switch newPhase {
            case .active:
                // App became active
                break
            case .inactive:
                // App is transitioning
                break
            case .background:
                // App moved to background
                break
            @unknown default:
                break
            }
        }
        .navigationTitle("Event Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }

    struct ViewEventList: View {

        let title: String

        var body: some View {
            VStack {
                // History timeline
                ViewEventsHistory()

                // Quick date filter toolbar
                ViewQuickDayFilter()
            }
        }
    }
}
