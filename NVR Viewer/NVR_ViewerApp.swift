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
    
    @AppStorage("background_fetch_events_epochtime")  var backgroundFetchEventsEpochtime: String = "0"
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
     
    let cNVR = APIRequester()
    let nvr = NVRConfig.shared()
    let notificationManager = NotificationManager()
    
    func setUpdNotificationManager() {
        delegate.notificationManager = notificationManager
    }
 
    @Environment(\.scenePhase) private var phase
    
    func scheduleAppRefresh()  {
        let request = BGAppRefreshTaskRequest(identifier: "viewu_refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
     
    var body: some Scene {
         
        WindowGroup {
            ContentView()
                .environmentObject(delegate)
                .environmentObject(notificationManager)
                .onAppear {
                    setUpdNotificationManager()
                }
        }
        .modelContainer(for: [ImageContainer.self]) 
        .backgroundTask(.appRefresh("viewu_refresh")) {
  
            await cNVR.fetchEventsInBackground(urlString: nvr.getUrl(), backgroundFetchEventsEpochtime: backgroundFetchEventsEpochtime, epsType: "background" )
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background:
                scheduleAppRefresh()
            default: break
            }
       }
    }
}

