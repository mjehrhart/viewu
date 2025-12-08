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
    
    @Published var epsSup2 = EndpointOptionsSuper.shared().list2 {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var epsSup3 = EndpointOptionsSuper.shared().list3 {
        willSet {
            objectWillChange.send()
        }
    }
     
    private func loadRocketSimConnect() {
        #if DEBUG
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
        #endif
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        loadRocketSimConnect()
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken;
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            //print("fcm", fcm)
            fcmID = fcm
        } else {
            Log.shared().print(page: "AppDelegate", fn: "messaging", type: "ERROR", text: "Oh No!::UIApplicationDelegateAdaptor::messaging()")
        }
    }
 
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
 
        //TODO verify this doesnt work correctly
        parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 1, applicationState: "active")
        
        
        completionHandler([[.banner, .badge, .sound]])
    }
 
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("AppDelegate::application::----------------------------------------------------------->didReceiveRemoteNotification")
        
        //        print(userInfo)
 
        DispatchQueue.main.async { [self] in
            switch application.applicationState {
            case .active:
                //print("1. do stuff in case App is active")
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "active")
            case .inactive:
                //print("2. do stuff in case App is .inactive")
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "inactive")
            case .background:
                //print("3. do stuff in case App is .background")
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "background")
            @unknown default:
                //print("4. default")
                parseUserInfo(userInfo: userInfo, transportType: "didReceiveRemoteNotification", newPage: 0, applicationState: "default")
            }
            
            completionHandler(.newData)
        }
    }
    
    func parseUserInfo(userInfo: [AnyHashable : Any], transportType: String, newPage: Int, applicationState: String ) {
        
        DispatchQueue.main.async { [self] in
            if let _ = userInfo["aps"] as? Dictionary<String, AnyObject> {
 
                print("[DEBUG] does this show anything")
                print(userInfo)
                
                var eps = EndpointOptions()
                var eps2 = EndpointOptionsSuper.EventMeta()
                let eps3 = EndpointOptionsSuper.EventMeta3()
                
                eps.transportType = "didReceiveRemoteNotification"
                eps2.transportType = "didReceiveRemoteNotification"
                eps3.transportType = "didReceiveRemoteNotification"
                
                if let msg = userInfo["id"] as? String {
                    eps.id = msg
                    eps2.id = msg
                    eps3.id = msg
                }
                if let msg = userInfo["cameraName"] as? String {
                    eps.cameraName = msg
                    eps2.cameraName = msg
                    eps3.cameraName = msg
                }
                if let msg = userInfo["types"] as? String {
                    //print(200, msg)
                    eps.type = msg
                    eps2.type = msg
                    eps3.type = msg
                }
                
                if let msg = userInfo["frameTime"] as? String {
                    //print("frameTime")
                    //print(msg)
                    eps.frameTime = Double(msg)
                    eps2.frameTime = Double(msg)
                    eps3.frameTime = Double(msg)
                }
                if let msg = userInfo["top_score"] as? String {
                    eps.score = Double(msg)
                    eps2.score = Double(msg)
                    eps3.score = Double(msg)
                }
                if let msg = userInfo["label"] as? String {
                    eps.label = msg
                    eps2.label = msg
                    eps3.label = msg
                }
                if let msg = userInfo["camera"] as? String {
                    eps.camera = msg
                    eps2.camera = msg
                    eps3.camera = msg
                }
                if let msg = userInfo["m3u8"] as? String {
                    eps.m3u8 = msg
                    eps2.m3u8 = msg
                    eps3.m3u8 = msg
                }
                if let msg = userInfo["mp4"] as? String {
                    eps.mp4 = msg
                    eps2.mp4 = msg
                    eps3.mp4 = msg
                }
                if let msg = userInfo["snapshot"] as? String {
                    eps.snapshot = msg
                    eps2.snapshot = msg
                    eps3.snapshot = msg
                }
                if let msg = userInfo["thumbnail"] as? String {
                    eps.thumbnail = msg
                    eps2.thumbnail = msg
                    eps3.thumbnail = msg
                }
                if let msg = userInfo["debug"] as? String {
                    eps.debug = msg
                    eps2.debug = msg
                    eps3.debug = msg
                }
                if let msg = userInfo["image"] as? String {
                    eps.image = msg
                    eps2.image = msg
                    eps3.image = msg
                }
                
                if let msg = userInfo["sub_label"] as? String? {
                    eps.sublabel = msg
                    eps2.sublabel = msg
                    eps3.sublabel = msg
                }
                
                if let msg = userInfo["current_zones"] as? String? {
                    eps.currentZones = msg
                    eps2.currentZones = msg
                    eps3.currentZones = msg
                }
                
                if let msg = userInfo["entered_zones"] as? String? {
                    eps.enteredZones = msg
                    eps2.enteredZones = msg
                    eps3.enteredZones = msg
                }
                
                if let msg = userInfo["start_time"] as? String? { 
                    if (msg != nil) {
                        eps.frameTime = Double(msg!)
                        eps2.frameTime = Double(msg!)
                        eps3.frameTime = Double(msg!)
                    }
                }
 
                //THIS USES EPS"3"
                //using epsSup.list3 and not eps3
                if eps.sublabel == nil {
                    eps.sublabel = ""
                    eps2.sublabel = ""
                    eps3.sublabel = ""
                }
                if eps.currentZones == nil {
                    eps.currentZones = ""
                    eps2.currentZones = ""
                    eps3.currentZones = ""
                }
                if eps.enteredZones == nil {
                    eps.enteredZones = ""
                    eps2.enteredZones = ""
                    eps3.enteredZones = ""
                }
                if eps.type == nil {
                    eps.type = "auto"
                    eps2.enteredZones = "auto"
                    eps3.enteredZones = "auto"
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
          
                EventStorage.shared.readAll3(completion: { res in
                    self.epsSup3 = res!
                    //TODO
                    self.epsSup.list3 = res!
                })
                
                
                //Navigation --> Send to ViewLive()
                notificationManager?.newPage = newPage
                notificationManager?.frameTime = eps.frameTime
                notificationManager?.eps = eps
                
            }
        }
    }
    
}























 
