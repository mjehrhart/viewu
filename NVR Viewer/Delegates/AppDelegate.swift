//
//  AppDelegate.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/20/24.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseMessaging
import SQLite3


class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    
    @AppStorage("fcm") private var fcmID: String = ""
    weak var notificationManager: NotificationManager?
    @ObservedObject var epsSup = EndpointOptionsSuper.shared()
 
    @Published var epsSup3 = EndpointOptionsSuper.shared().list3 {
        willSet {
            objectWillChange.send()
        }
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // ensure NotificationServiceExtension has the latest auth/cache in App Group
        _ = NotificationAuthShared.syncFromStandardDefaults()
        NotificationAuthShared.syncFromStandardDefaults()

        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken;
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            
            fcmID = fcm
        } else {
            Log.error(page: "AppDelegate", fn: "messaging", "Oh No!::UIApplicationDelegateAdaptor::messaging()")
        }
    }
 
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
  
        parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 1, applicationState: "active")
        
        
        completionHandler([[.banner, .badge, .sound]])
    }
 
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        
        DispatchQueue.main.async { [self] in
            switch application.applicationState {
            case .active:
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "active")
            case .inactive:
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "inactive")
            case .background:
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "background")
            @unknown default:
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "default")
            }
            
            completionHandler(.newData)
        }
    }
    
    func parseUserInfo(userInfo: [AnyHashable : Any], transportType: String, newPage: Int, applicationState: String ) {
        
        DispatchQueue.main.async { [self] in
            if let _ = userInfo["aps"] as? Dictionary<String, AnyObject> {
  
                var eps = EndpointOptions()
                
                eps.transportType = "didReceiveRemoteNotification"
                
                if let msg = userInfo["id"] as? String {
                    eps.id = msg
                }
                if let msg = userInfo["cameraName"] as? String {
                    eps.cameraName = msg
                }
                if let msg = userInfo["types"] as? String {
                    eps.type = msg
                }
                
                if let msg = userInfo["frameTime"] as? String { 
                    eps.frameTime = Double(msg)
                }
                if let msg = userInfo["score"] as? String {
                    eps.score = Double(msg)
                }
                if let msg = userInfo["label"] as? String {
                    eps.label = msg
                }
                if let msg = userInfo["camera"] as? String {
                    eps.camera = msg
                }
                if let msg = userInfo["m3u8"] as? String {
                    eps.m3u8 = msg
                }
                if let msg = userInfo["mp4"] as? String {
                    eps.mp4 = msg
                }
                if let msg = userInfo["snapshot"] as? String {
                    eps.snapshot = msg
                }
                if let msg = userInfo["thumbnail"] as? String {
                    eps.thumbnail = msg
                }
                if let msg = userInfo["debug"] as? String {
                    eps.debug = msg
                }
                if let msg = userInfo["image"] as? String {
                    eps.image = msg
                }
                
                if let msg = userInfo["sub_label"] as? String? {
                    eps.sublabel = msg
                }
                
                if let msg = userInfo["current_zones"] as? String? {
                    eps.currentZones = msg
                }
                
                if let msg = userInfo["entered_zones"] as? String? {
                    eps.enteredZones = msg
                }
                
                if let msg = userInfo["start_time"] as? String? { 
                    if (msg != nil) {
                        eps.frameTime = Double(msg!)
                    }
                }
                
                if eps.sublabel == nil {
                    eps.sublabel = ""
                }
                
                if eps.currentZones == nil {
                    eps.currentZones = ""
                }
                
                if eps.enteredZones == nil {
                    eps.enteredZones = ""
                }
                
                if eps.type == nil {
                    eps.type = "auto"
                }
                
                //OPTION 3
                let _ = EventStorage.shared.insertOrUpdate(id: eps.id!,
                                                           frameTime: eps.frameTime!,
                                                           score: eps.score!,
                                                           type: eps.type!, //eps.types!, //TODO
                                                           cameraName: eps.cameraName!,
                                                           label: eps.label!,
                                                           thumbnail: eps.thumbnail!,
                                                           snapshot: eps.snapshot!,
                                                           m3u8: eps.m3u8!,
                                                           mp4: eps.mp4 ?? "",
                                                           camera: eps.camera!,
                                                           debug: eps.debug!,
                                                           image: eps.image!,
                                                           transportType: eps.transportType!,
                                                           subLabel: eps.sublabel!, // ADDED THIS 5/26
                                                           currentZones: eps.currentZones!,
                                                           enteredZones: eps.enteredZones!
                )
                
                
                //TODO either remove this or revisit the flow
                notificationManager?.newPage = newPage
                notificationManager?.frameTime = eps.frameTime
                notificationManager?.eps = eps
                
            }
        }
    }
    
}
