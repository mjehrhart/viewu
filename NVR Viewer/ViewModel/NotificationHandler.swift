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
                Log.warning(page: "NotificationHandler", fn: "askPermission", message)
            }
        }
    }

    /// Sends a push-style local notification with an optional image attachment.
    ///
    /// - Parameters:
    ///   - body: Body text for the notification
    ///   - urlString: Image URL to attach (if download succeeds)
    ///   - authHeaders: Headers to use when downloading the image (e.g. from buildAuthHeaders()).
    ///                 Pass [:] for none/public images.
    func sendNotificationMessage(
        body: String,
        urlString: String,
        authHeaders: [String: String] = [:]
    ) {

        let center = UNUserNotificationCenter.current()

        // Clear any pending ones so the latest one is what the user sees.
        center.removeAllPendingNotificationRequests()

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "NVR Viewer"
        content.body = body
        content.sound = .default

        func scheduleNotification(with content: UNMutableNotificationContent) {
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error = error {
                    Log.error(
                        page: "NotificationHandler",
                        fn: "sendNotificationMessage",
                        "Failed to schedule notification: \(error.localizedDescription)"
                    )
                }
            }
        }

        // If URL is invalid, just send text-only notification
        guard let url = URL(string: urlString) else {
            Log.warning(
                page: "NotificationHandler",
                fn: "sendNotificationMessage",
                "Invalid image URL, sending text-only notification"
            )
            scheduleNotification(with: content)
            return
        }

        // Build URLRequest so we can apply auth headers (.bearer/.frigate/.cloudflare/etc.)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        // Apply headers from your existing buildAuthHeaders() pattern
        for (k, v) in authHeaders {
            request.setValue(v, forHTTPHeaderField: k)
        }

        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in

            if let error = error {
                Log.error(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    "Image download failed: \(error.localizedDescription)"
                )
                scheduleNotification(with: content)
                return
            }

            // Validate HTTP status if available
            if let http = response as? HTTPURLResponse {
                if !(200...299).contains(http.statusCode) {
                    Log.warning(
                        page: "NotificationHandler",
                        fn: "sendNotificationMessage",
                        "Image fetch HTTP \(http.statusCode); sending text-only"
                    )
                    scheduleNotification(with: content)
                    return
                }
            }

            // Validate mime type (reject HTML, JSON, etc.)
            let mime = response?.mimeType?.lowercased()
            if let mime = mime, !mime.hasPrefix("image/") {
                Log.warning(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    "Image fetch returned mime=\(mime); sending text-only"
                )
                scheduleNotification(with: content)
                return
            }

            guard let tempURL = tempURL else {
                Log.warning(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    "Image download returned no file URL"
                )
                scheduleNotification(with: content)
                return
            }

            // Choose an extension: prefer URL extension, else infer from mime
            let extFromURL = url.pathExtension
            let ext: String = {
                if !extFromURL.isEmpty { return extFromURL }
                switch mime {
                case "image/jpeg": return "jpg"
                case "image/png":  return "png"
                case "image/gif":  return "gif"
                case "image/webp": return "webp"
                case "image/heic": return "heic"
                default:           return "jpg"
                }
            }()

            let identifier = ProcessInfo.processInfo.globallyUniqueString
            let targetURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(identifier)
                .appendingPathExtension(ext)

            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }

                try FileManager.default.moveItem(at: tempURL, to: targetURL)

                let attachment = try UNNotificationAttachment(
                    identifier: identifier,
                    url: targetURL,
                    options: nil
                )

                content.attachments = [attachment]
                scheduleNotification(with: content)

            } catch {
                Log.error(
                    page: "NotificationHandler",
                    fn: "sendNotificationMessage",
                    "Failed to create notification attachment: \(error.localizedDescription)"
                )
                scheduleNotification(with: content)
            }
        }

        task.resume()
    }
}

