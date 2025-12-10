//
//  NotificationManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/7/24.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {

    // These seem to be used for navigation / deep linking from a notification
    @Published var newPage: Int?
    @Published var frameTime: Double?
    @Published var eps: EndpointOptions?

    @Published private(set) var hasPermission = false

    init() {
        // Check current authorization status on startup
        Task {
            await getAuthStatus()
        }
    }

    /// Request notification authorization from the user.
    func request() async {
        do {
            let center = UNUserNotificationCenter.current()
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await getAuthStatus()
        } catch {
            Log.shared().print(page: "NotificationManager",
                               fn: "request",
                               type: "ERROR",
                               text: "authorization error: \(error.localizedDescription)")
        }
    }

    /// Refresh `hasPermission` based on the current system settings.
    func getAuthStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            hasPermission = true
        default:
            hasPermission = false
        }
    }

    /// Convenience helper for callers that don't want to bind to `hasPermission`.
    func isAuthorized() -> Bool {
        hasPermission
    }
}

// MARK: - Remove
////
////  NotificationManager.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/7/24.
////
//
//import Foundation
//import UserNotifications
//
//@MainActor
//class NotificationManager: ObservableObject{
//    
//    @Published var newPage: Int?
//    @Published var frameTime: Double?
//    @Published var eps: EndpointOptions?
//    
//    @Published private(set) var hasPermission = false
//    
//    init() {
//        Task{
//            await getAuthStatus()
//        }
//    }
//    
//    func request() async{
//        do {
//            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
//             await getAuthStatus()
//        } catch{
//            print(error)
//        }
//    }
//    
//    func getAuthStatus() async {
//        let status = await UNUserNotificationCenter.current().notificationSettings()
//        switch status.authorizationStatus {
//        case .authorized, .ephemeral, .provisional:
//            hasPermission = true
//        default:
//            hasPermission = false
//        }
//    }
//    
//    func isAuthorized() -> Bool {
//        return hasPermission
//    }
//}
