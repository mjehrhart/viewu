//
//  NVR_ViewerApp.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import BackgroundTasks

@main
struct NVR_ViewerApp: App {

    // MARK: - Persistent settings

    @AppStorage("background_fetch_events_epochtime")
    private var backgroundFetchEventsEpochtime: String = "0"

    // MARK: - App delegate bridge

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate

    // MARK: - Services / singletons

    private let api = APIRequester()
    private let nvr = NVRConfig.shared()          // classic singleton
    private let notificationManager = NotificationManager()

    // MARK: - Scene phase

    @Environment(\.scenePhase)
    private var scenePhase

    // MARK: - Helpers

    /// Wire the same NotificationManager instance into the app delegate
    /// so push callbacks and SwiftUI views share a single source of truth.
    private func setUpNotificationManager() {
        delegate.notificationManager = notificationManager
    }

    /// Schedule the next background refresh for this app.
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "viewu_refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            Log.debug(page: "ViewEventDetail",
                      fn: "scheduleAppRefresh",
                      "BGAppRefreshTask 'viewu_refresh' scheduled.")
            #endif
        } catch {
            #if DEBUG
            Log.error(page: "ViewEventDetail",
                      fn: "scheduleAppRefresh",
                      "Failed to schedule BGAppRefreshTask: \(error.localizedDescription)")
            #endif
        }
    }

    /// Keep App Group values fresh so NotificationExtension can always read creds.
    private func syncNotificationAuthToAppGroup(reason: String) {
        NotificationAuthShared.syncFromStandardDefaults()

        #if DEBUG
        // Safe readback (lengths only)
        if let snap = NotificationAuthShared.load() {
            Log.debug(
                page: "NVR_ViewerApp",
                fn: "syncNotificationAuthToAppGroup",
                "[app] synced (\(reason)) suite=\(NotificationAuthShared.suiteName) idLen=\(snap.cloudFlareClientId.count) secretLen=\(snap.cloudFlareSecret.count)"
            )
        } else {
            Log.warning(
                page: "NVR_ViewerApp",
                fn: "syncNotificationAuthToAppGroup",
                "[app] App Group unavailable (\(reason)) suite=\(NotificationAuthShared.suiteName)"
            )
        }
        #endif
    }

    init() {
        syncNotificationAuthToAppGroup(reason: "app init")
    }

    // MARK: - Body

    var body: some Scene {

        WindowGroup {
            ContentView()
                .environmentObject(delegate)
                .environmentObject(notificationManager)
                .onAppear {
                    // Ensure the delegate and SwiftUI world share the same instance
                    setUpNotificationManager()
                }
        }
        .modelContainer(for: [ImageContainer.self])

        // Background fetch: iOS will call this when the "viewu_refresh"
        // app refresh task fires. When this async block returns,
        // the task is considered complete.
        .backgroundTask(.appRefresh("viewu_refresh")) {
            await api.fetchEventsInBackground(
                urlString: nvr.getUrl(),
                backgroundFetchEventsEpochtime: backgroundFetchEventsEpochtime,
                epsType: "background",
                authType: nvr.getAuthType()
            )
        }

        // Re-schedule background refresh whenever the app goes to background.
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Optional but recommended: ensure latest creds are in App Group
                syncNotificationAuthToAppGroup(reason: "scenePhase background")
                scheduleAppRefresh()
            default:
                break
            }
        }
    }
}
