//
//  NotificationHandler.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/7/24.
//

import Foundation
import UserNotifications

class NotificationHandler{
    
    func askPermission(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound ]){success,error in
            if success {
                print("Cool, user accepted notifications")
            } else {
                print("Oh no, user denided notifications")
            }
        }
    }
    
    func sendNotificationMessage(body: String, urlString: String) {
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
         
        var trigger: UNNotificationTrigger?
        trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false) 
        
        let content = UNMutableNotificationContent()
        content.title = "NVR Viewer"
        content.body = body
        //content.subtitle = "subtitle"
        content.sound = UNNotificationSound.default
 
        ///======================================================== ///
        if let url = URL(string: urlString) {

            let pathExtension = url.pathExtension

            let task = URLSession.shared.downloadTask(with: url) { (result, response, error) in
                if let result = result {

                    let identifier = ProcessInfo.processInfo.globallyUniqueString
                    let target = FileManager.default.temporaryDirectory.appendingPathComponent(identifier).appendingPathExtension(pathExtension)

                    do {
                        try FileManager.default.moveItem(at: result, to: target)

                        let attachment = try UNNotificationAttachment(identifier: identifier, url: target, options: nil)
                        content.attachments.append(attachment)

                        let notification = UNNotificationRequest(identifier: Date().description, content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(notification, withCompletionHandler: { (error) in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        })
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
        ///======================================================== ///  
    }
}
