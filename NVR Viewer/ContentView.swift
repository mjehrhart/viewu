//
//  ContentView.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI
import CocoaMQTT
import SwiftData
import TipKit
import BackgroundTasks
import JWTKit 

private let appGroupDefaults: UserDefaults = UserDefaults(suiteName: "group.com.viewu.app") ?? .standard

@MainActor
struct ContentView: View {
    // MARK: - Singletons / shared state
    
    @ObservedObject private var filter2 = EventFilter.shared()
    @ObservedObject private var config = NVRConfigurationSuper2.shared()
    
    private let nvr = NVRConfig.shared()
    private let api = APIRequester()
    
    @EnvironmentObject private var notificationManager2: NotificationManager
    
    // MARK: - View state
    
    @State private var selection: Int = 0
    
    @StateObject private var nts = NotificationTemplateString.shared()
    @StateObject private var mqttManager = MQTTManager.shared()
    //@StateObject private var filter2 = EventFilter.shared()
    
    @State private var showFilter = false
    @State private var showEventList = false
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showConnection = false
    @State private var showNVR = false
    @State private var showLog = false
    @State private var showNotificationManager = false
    
    @AppStorage("developerModeIsOn") private var developerModeIsOn = false
    @AppStorage("showLogView") private var showLogView: Bool = false
    @AppStorage("showNVRView") private var showNVRView: Bool = false
    @AppStorage("notificationModeIsOn") private var notificationModeIsOn = UserDefaults.standard.bool(forKey: "notificationModeIsOn")
    @AppStorage("frigateAlertsRetain") private var frigateAlertsRetain: Int = 10
    @AppStorage("frigateDetectionsRetain") private var frigateDetectionsRetain: Int = 10
    @AppStorage("frigateVersion") private var frigateVersion: String = "0.0-0"
    @AppStorage("background_fetch_events_epochtime") private var backgroundFetchEventsEpochtime: String = "0"
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    @AppStorage("showTips") private var showTips: Bool = true
    
    //Needed for sharing values with NotificationExtension
    @AppStorage("authType") private var authType: AuthType = .none
    //@AppStorage("cloudFlareClientId") private var cloudFlareClientId: String = ""
    @AppStorage("cloudFlareClientId", store: appGroupDefaults)  private var cloudFlareClientId: String = ""
    //@AppStorage("cloudFlareSecret") private var cloudFlareSecret: String = ""
    @AppStorage("cloudFlareClientSecret", store: appGroupDefaults) private var cloudFlareSecret: String = ""
    
    // Prevent double-fetching events on startup / quick app switches
    @AppStorage("lastEventsFetchTime") private var lastEventsFetchTime: TimeInterval = 0
    private let minFetchInterval: TimeInterval = 60
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var path = NavigationPath()
    
    @State private var hasLoadedConfigThisLaunch = false
 
    // MARK: - Init
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font : UIFont(name: "Georgia-Bold", size: 20)!
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                ZStack {
                    // fake status bar background
                    GeometryReader { reader in
                        Color.secondary
                            .frame(height: reader.safeAreaInsets.top, alignment: .top)
                            .ignoresSafeArea()
                    }
                    
                    switch selection {
                    case 0:
                        if isOnboarding {
                            ViewOnBoarding()
                        } else {
                            ViewEventListHome()
                        }
                        
                    case 1:
                        ViewEventDetail(
                            text: convertDateTime(time: notificationManager2.frameTime!),
                            container: notificationManager2.eps!,
                            showButton: true,
                            showClip: false
                        )
                        
                    case 2:
                        ViewNVRDetails()
                        
                    default:
                        ViewEventListHome()
                    }
                }
            }
            .task {
                // Only do this once per process lifetime
                guard !hasLoadedConfigThisLaunch else { return }
                hasLoadedConfigThisLaunch = true

                // Initial config + events load (off main where possible)
                await loadInitialData()
            }
            .onReceive(notificationManager2.$newPage) {
                guard let notificationSelection = $0 else { return }
                selection = notificationSelection
            }
            .onChange(of: scenePhase) { _, newScenePhase in
                handleScenePhaseChange(newScenePhase)
            }
            .onAppear {
                  
                migrateLegacyCloudflareSecretIfNeeded()
                Task {
                    // Give the first frame a moment so launch feels snappier
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                    
                    await sheduleBackgroundTask()
                    await checkConnection()
                    
                    // Connect to MQTT broker
                    mqttManager.initializeMQTT()
                    mqttManager.connect()
                }
            }
            .environmentObject(mqttManager)
            .environmentObject(nvr)   // classic singleton used as environment object
            .scrollContentBackground(.hidden)
            .navigationBarBackButtonHidden()
            .navigationDestination(isPresented: $showEventList) {
                ViewEventListHome()
            }
            .navigationDestination(isPresented: $showNVR) {
                ViewNVRDetails()
            }
            .navigationDestination(isPresented: $showSettings) {
                ViewSettings(
                    title: "Settings",
                    reloadConfig: {
                        await loadConfig()
                    }
                )
                .environmentObject(nvr)
                .environmentObject(mqttManager)
            } 
            .navigationDestination(isPresented: $showConnection) {
                ViewConnection(title: "Connection")
                    .environmentObject(nvr)
                    .environmentObject(mqttManager)
            }
            .navigationDestination(isPresented: $showLog) {
                ViewLog()
            }
            .navigationDestination(isPresented: $showCamera) {
                ViewCamerasList(title: "Live Cameras")
            }
            .navigationDestination(isPresented: $showNotificationManager) {
                ViewAPN(title: "Notification Manager")
            } 
            .navigationDestination(for: Cameras2.self) { config in
                ViewCameraDetails2(
                    text: "\(config.name.uppercased()) Camera Details",
                    cameras: config
                )
            }
            .navigationDestination(for: EndpointOptions.self) { eps in
                ViewEventDetail(
                    text: convertDateTime(time: eps.frameTime!),
                    container: eps,
                    showButton: false,
                    showClip: true
                )
            } 
            .sheet(isPresented: $showFilter) {
                ViewFilter()
                    .presentationDetents([.large])
            }
            .toolbarBackground(.clear, for: .bottomBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !isOnboarding {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer(minLength: 0)
                        
                        HStack(spacing: 20) {
                            // MARK: - Filter
                            BottomBarItem(
                                title: "Filter",
                                systemImage: "calendar.day.timeline.leading",
                                isHighlighted: showFilter
                            ) {
                                showFilter.toggle()
                            }
                            
                            // MARK: - Cameras
                            BottomBarItem(
                                title: "Cameras",
                                systemImage: "web.camera",
                                isHighlighted: showCamera
                            ) {
                                showCamera.toggle()
                            }
                            
                            // MARK: - Notifications
                            if notificationModeIsOn {
                                BottomBarItem(
                                    title: "Notifications",
                                    systemImage: "app.badge",
                                    isHighlighted: nts.notificationPaused || showNotificationManager,
                                    foreground: nts.notificationPaused ? .orange : .secondary
                                ) {
                                    showNotificationManager.toggle()
                                }
                            }
                            
                            // MARK: - NVR (dev)
                            if showNVRView {
                                BottomBarItem(
                                    title: "NVR",
                                    systemImage: "arrow.triangle.2.circlepath.circle",
                                    isHighlighted: selection == 2
                                ) {
                                    notificationManager2.newPage = 2
                                    selection = 2
                                }
                            }
                            
                            // MARK: - Log (dev)
                            if showLogView {
                                BottomBarItem(
                                    title: "Log",
                                    systemImage: "note.text",
                                    isHighlighted: showLog
                                ) {
                                    showLog.toggle()
                                }
                            }
                            
                            // MARK: - Settings
                            BottomBarItem(
                                title: "Settings",
                                systemImage: "gearshape",
                                isHighlighted: showSettings
                            ) {
                                showSettings.toggle()
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .frame(maxWidth: 500)
                        .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
    
    // MARK: - Async loading / lifecycle
    
    private func loadInitialData() async {
        await loadConfig()
        await fetchEventsIfNeeded(source: "ctask")
    }
    
    private func handleScenePhaseChange(_ newScenePhase: ScenePhase) {
        Task {
            if newScenePhase == .active {
                await fetchEventsIfNeeded(source: "scenePhase")
            }
        }
    }
    
    private func loadConfig() async {
        let url = nvr.getUrl()
        
        await api.fetchNVRConfig(
            urlString: url,
            authType: nvr.getAuthType()
        ) { data, error in
            
            guard let data = data else { return }
            
            if developerModeIsOn {
                Log.debug(
                    page: "ContentView",
                    fn: "loadConfig", readData(data)
                )
            }
            
            // Decode off the main actor so UI stays snappy
            Task.detached(priority: .userInitiated) {
                do {
                    let configuration = try JSONDecoder().decode(
                        NVRConfigurationCall2.self,
                        from: data
                    )
                    
                    await MainActor.run {
                        applyConfig(configuration)
                        cleanupSnapshots(using: configuration)
                    }
                } catch {
                    await MainActor.run {
                        logConfigDecodeError(data: data, error: error)
                    }
                }
            }
        }
    }
    
    private func fetchEventsIfNeeded(source: String) async {
        guard shouldFetchEvents() else { return }
        
        await api.fetchEventsInBackground(
            urlString: nvr.getUrl(),
            backgroundFetchEventsEpochtime: backgroundFetchEventsEpochtime,
            epsType: source,
            authType: nvr.getAuthType()
        )
        
        markEventsFetched()
    }
    
    private func shouldFetchEvents() -> Bool {
        let now = Date().timeIntervalSince1970
        return (now - lastEventsFetchTime) > minFetchInterval
    }
    
    private func markEventsFetched() {
        lastEventsFetchTime = Date().timeIntervalSince1970
    }
    
    private func checkConnection() async {
        let urlString = nvr.getUrl()

        do {
            try await api.checkConnectionStatus(
                urlString: urlString,
                authType: authType
            ) { _, error in
                Task { @MainActor in
                    nvr.connectionState = (error == nil) ? .connected : .disconnected
                }
            }
        } catch {
            Log.error(page: "ContentView",
                      fn: "checkConnection",
                      "checkConnection error: \(error)")

            await MainActor.run {
                nvr.connectionState = .disconnected
            }
        }
    }
    
//    private func checkConnection() async {
//        let urlString = nvr.getUrl()
//        
//        do {
//            try await api.checkConnectionStatus(
//                urlString: urlString,
//                authType: authType
//            ) { _, error in
//                if let error = error {
//                    nvr.connectionState = .disconnected
//                } else {
//                    nvr.connectionState = .connected 
//                }
//            }
//        } catch {
//            Log.error(page: "ContentView",
//                               fn: "checkConnection", "checkConnection error: \(error)")
//            nvr.connectionState = .disconnected
//        }
//    }
    
    // MARK: - Config helpers
    
    private func applyConfig(_ configuration: NVRConfigurationCall2) {
        config.item = configuration
        
        filter2.setCameras(items: configuration.cameras) 
        filter2.setObject(items: configuration.cameras)
        filter2.setZones(items: configuration.cameras)
        
        frigateVersion = configuration.version
        frigateAlertsRetain = configuration.record.alerts.retain.days
        frigateDetectionsRetain = configuration.record.detections.retain.days
    }
    
    private func cleanupSnapshots(using configuration: NVRConfigurationCall2) {
        // NOTE: This still runs on the main actor (like before).
        // If EventStorage is thread-safe you can move this to a background
        // actor in the future for even better perf.
        for (_, value) in configuration.cameras {
            let daysBack = value.snapshots.retain.default
            let db = Int(daysBack)   // or just `let db = daysBack` if it's already Int
            _ = EventStorage.shared.delete(daysBack: db, cameraName: value.name)
        }
    }
    
    private func logConfigDecodeError(data: Data, error: Error) {
 
        do {
            if let json = try JSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            ) as? [String: Any] {
                Log.warning(
                    page: "ContentView",
                    fn: "logConfigDecodeError", "\(json)"
                )
            }
        } catch {
            Log.error(
                page: "ContentView",
                fn: "logConfigDecodeError", "\(error)"
            )
        }
    }
    
    // MARK: - Background task
    
    func sheduleBackgroundTask() async {
        let request = BGAppRefreshTaskRequest(identifier: "viewu_refresh")
        request.earliestBeginDate = Calendar.current.date(
            byAdding: .second,
            value: 30 * 60,
            to: Date()
        )
        do {
            try BGTaskScheduler.shared.submit(request)
            Log.debug(page: "ContentView",
                               fn: "sheduleBackgroundTask", "Background Task Scheduled!")
        } catch {
            Log.error(page: "ContentView",
                               fn: "sheduleBackgroundTask", "Scheduling Error \(error.localizedDescription)")
        }
    }
    
    // MARK: - Date helpers
    
    private func convertTime(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: date)
    }
    
    private func convertDateTime(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = .current
        var localDate = dateFormatter.string(from: date)
        localDate.replace("at", with: "")
        return localDate
    }
}

 
// MARK: - Label style

struct VerticalLabelStyle: LabelStyle {
    var show: Bool
    
    init(show: Bool) {
        self.show = show
    }
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon.font(.system(size: 18))
            configuration.title.font(.system(size: 10))
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationManager())
            .environmentObject(NVRConfig.shared())
    }
}

// MARK: - Transitions

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        AnyTransition.slide
    }
}

// MARK: - Debug helpers

func printData(_ data: Data) {
    let string = String(data: data, encoding: .utf8) ?? "Unable to decode data"
    print("\(string)")
}

func readData(_ data: Data) -> String {
    let string = String(data: data, encoding: .utf8) ?? "Unable to decode data"
    return string
}

// MARK: - Bottom bar item

struct BottomBarItem: View {
    let title: String
    let systemImage: String
    var isHighlighted: Bool = false
    var foreground: Color? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .frame(minWidth: 44)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isHighlighted ? Color.accentColor.opacity(0.15) : .clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            foreground ?? (isHighlighted ? Color.accentColor : Color.secondary)
        )
    }
}

private func migrateLegacyCloudflareSecretIfNeeded() {
    let legacy = (appGroupDefaults.string(forKey: "cloudFlareSecret") ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    let canonical = (appGroupDefaults.string(forKey: "cloudFlareClientSecret") ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    if canonical.isEmpty, !legacy.isEmpty {
        appGroupDefaults.set(legacy, forKey: "cloudFlareClientSecret")
    }
}
