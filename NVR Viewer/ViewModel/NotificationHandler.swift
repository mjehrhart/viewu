//
//  NotificationHandler.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/7/24.
//

import Foundation
import UserNotifications

final class NotificationHandler {

    /// Ask the user for notification permission.
    func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { success, error in
            if success {
                // Permission granted – nothing else to do here for now.
            } else {
                let message = error?.localizedDescription ?? "User denied notifications"
                Log.shared().print(
                    page: "NotificationHandler",
                    fn: "askPermission",
                    type: "WARNING",
                    text: message
                )
            }
        }
    }

    /// Sends a push-style local notification with an optional image attachment.
    ///
    /// - Parameters:
    ///   - body: The body text of the notification.
    ///   - urlString: URL string to an image to attach to the notification.
    ///     If the image fails to load, a text-only notification is still delivered.
    func sendNotificationMessage(body: String, urlString: String) {

        let center = UNUserNotificationCenter.current()

        // Clear any pending ones so the latest one is what the user sees.
        center.removeAllPendingNotificationRequests()

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "NVR Viewer"
        content.body = body
        content.sound = .default

        // Helper to schedule a notification with the current content
        func scheduleNotification(with content: UNMutableNotificationContent) {
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error = error {
                    Log.shared().print(
                        page: "NotificationHandler",
                        fn: "sendNotificationMessage",
                        type: "ERROR",
                        text: "Failed to schedule notification: \(error.localizedDescription)"
                    )
                }
            }
        }

        // If URL is invalid, just send text-only notification
        guard let url = URL(string: urlString) else {
            Log.shared().print(
                page: "NotificationHandler",
                fn: "sendNotificationMessage",
                type: "WARNING",
                text: "Invalid image URL, sending text-only notification"
            )
            scheduleNotification(with: content)
            return
        }

        let pathExtension = url.pathExtension

        // Download the image and attach it to the notification
        let task = URLSession.shared.downloadTask(with: url) { (tempURL, _, error) in

            if let error = error {
                Log.shared().print(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    type: "ERROR",
                    text: "Image download failed: \(error.localizedDescription)"
                )
                // Fallback to text-only notification
                scheduleNotification(with: content)
                return
            }

            guard let tempURL = tempURL else {
                Log.shared().print(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    type: "WARNING",
                    text: "Image download returned no file URL"
                )
                scheduleNotification(with: content)
                return
            }

            let identifier = ProcessInfo.processInfo.globallyUniqueString
            let targetURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(identifier)
                .appendingPathExtension(pathExtension)

            do {
                try FileManager.default.moveItem(at: tempURL, to: targetURL)

                let attachment = try UNNotificationAttachment(
                    identifier: identifier,
                    url: targetURL,
                    options: nil
                )
                content.attachments = [attachment]

                scheduleNotification(with: content)
            } catch {
                Log.shared().print(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    type: "ERROR",
                    text: "Failed to create notification attachment: \(error.localizedDescription)"
                )
                // Still send a text-only notification
                scheduleNotification(with: content)
            }
        }

        task.resume()
    }
}
