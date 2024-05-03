//
//  NVR_ViewerApp.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/1/24.
//

import SwiftUI

@main
struct NVR_ViewerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
     
    let notificationManager = NotificationManager()
    
    func setUpdNotificationManager() {
        delegate.notificationManager = notificationManager
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
    }
}

