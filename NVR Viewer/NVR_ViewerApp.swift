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
    @MainActor
    func syncNotificationAuthToAppGroup() {
        let suite = "group.com.viewu.app"
        guard let group = UserDefaults(suiteName: suite) else { return }
        let standard = UserDefaults.standard

        let idKey = "cloudFlareClientId"
        let secretKey = "cloudFlareClientSecret"

        // Read current canonical app-group values
        let groupId = (group.string(forKey: idKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let groupSecret = (group.string(forKey: secretKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // If app-group already has values, DO NOT overwrite them.
        if !groupId.isEmpty && !groupSecret.isEmpty {
            Log.debug(page: "NVR_ViewerApp", fn: "syncNotificationAuthToAppGroup",
                      "[app] sync skipped (app group already set) suite=\(suite) idLen=\(groupId.count) secretLen=\(groupSecret.count)")
            return
        }

        // Otherwise migrate from standard / legacy keys
        func firstNonEmpty(_ ud: UserDefaults, _ keys: [String]) -> String {
            for k in keys {
                let v = (ud.string(forKey: k) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !v.isEmpty { return v }
            }
            return ""
        }

        let id = firstNonEmpty(standard, [idKey, "cloudflareClientId", "cloudflareClientid", "cloudflareClientID"])
        let secret = firstNonEmpty(standard, [secretKey, "cloudflareClientSecret", "clouflareClientSecret", "cloudFlareSecret"])

        if !id.isEmpty { group.set(id, forKey: idKey) }
        if !secret.isEmpty { group.set(secret, forKey: secretKey) }

        Log.debug(page: "NVR_ViewerApp", fn: "syncNotificationAuthToAppGroup",
                  "[app] synced (migrate) suite=\(suite) idLen=\(id.count) secretLen=\(secret.count)")
    }


    init() {
        syncNotificationAuthToAppGroup()
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
                syncNotificationAuthToAppGroup()
                scheduleAppRefresh()
            default:
                break
            }
        }
    }
}
