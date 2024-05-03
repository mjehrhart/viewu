//
//  NotificationManager.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/7/24.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject{
    
    @Published var newPage: Int?
    @Published var frameTime: Double?
    @Published var eps: EndpointOptions?
    
    @Published private(set) var hasPermission = false
    
    init() {
        Task{
            await getAuthStatus()
        }
    }
    
    func request() async{
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
             await getAuthStatus()
        } catch{
            print(error)
        }
    }
    
    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            hasPermission = true
        default:
            hasPermission = false
        }
    }
    
    func isAuthorized() -> Bool {
        return hasPermission
    }
}
