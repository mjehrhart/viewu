//
//  NotificationService.swift
//  NotificationExtension
//

import UserNotifications
import Foundation
import OSLog

final class NotificationService: UNNotificationServiceExtension {

    private let log = OSLog(subsystem: "NSE", category: "NSE")

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    // Turn off once you're done testing
    private let prefixTitleForDebug = false

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        os_log("[ext] didReceive fired id=%{public}@", log: log, type: .fault, request.identifier)

        guard let bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        if prefixTitleForDebug {
            bestAttemptContent.title = "[EXT-RAN] " + bestAttemptContent.title
        }

        let userInfo = request.content.userInfo
        os_log("[ext] userInfo=%{public}@", log: log, type: .info, String(describing: userInfo))

        let urlString =
            (userInfo["snapshot"] as? String) ??
            (userInfo["image_url"] as? String) ??
            (userInfo["thumbnail"] as? String) ??
            (userInfo["image"] as? String)

        guard let urlString, let url = URL(string: urlString) else {
            os_log("[ext] No usable image URL in payload; delivering without attachment", log: log, type: .fault)
            contentHandler(bestAttemptContent)
            return
        }

        os_log("[ext] imageURL=%{public}@", log: log, type: .info, url.absoluteString)

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("image/*", forHTTPHeaderField: "Accept")

        applyAuthHeaders(to: &req)

        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 15

        URLSession(configuration: cfg).dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                os_log("[ext] download error=%{public}@", log: self.log, type: .fault, error.localizedDescription)
                contentHandler(bestAttemptContent)
                return
            }

            let http = response as? HTTPURLResponse
            let status = http?.statusCode ?? -1
            let mime = http?.value(forHTTPHeaderField: "Content-Type") ?? "unknown"

            os_log("[ext] download status=%{public}d mime=%{public}@", log: self.log, type: .info, status, mime)

            guard (200...299).contains(status), let data, !data.isEmpty else {
                os_log("[ext] download failed/empty (bytes=%{public}d)", log: self.log, type: .fault, data?.count ?? 0)
                contentHandler(bestAttemptContent)
                return
            }

            // If Cloudflare Access blocks you, you'll get HTML (login page)
            if !mime.lowercased().contains("image/") {
                let snippet = String(data: data.prefix(200), encoding: .utf8) ?? "<non-utf8>"
                os_log("[ext] NOT an image. First 200 bytes=%{public}@", log: self.log, type: .fault, snippet)
                contentHandler(bestAttemptContent)
                return
            }

            let fileExt: String
            let typeHint: String
            if mime.lowercased().contains("png") {
                fileExt = "png"
                typeHint = "public.png"
            } else {
                fileExt = "jpg"
                typeHint = "public.jpeg"
            }

            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let fileURL = tmpDir
                .appendingPathComponent("snapshot-\(UUID().uuidString)")
                .appendingPathExtension(fileExt)

            do {
                try data.write(to: fileURL, options: [.atomic])

                let attachment = try UNNotificationAttachment(
                    identifier: "snapshot",
                    url: fileURL,
                    options: [UNNotificationAttachmentOptionsTypeHintKey: typeHint]
                )

                bestAttemptContent.attachments = [attachment]
                os_log("[ext] attachment created OK (count=%{public}d)", log: self.log, type: .info, bestAttemptContent.attachments.count)

                contentHandler(bestAttemptContent)
            } catch {
                os_log("[ext] attachment failed error=%{public}@", log: self.log, type: .fault, error.localizedDescription)
                contentHandler(bestAttemptContent)
            }
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        os_log("[ext] timeWillExpire", log: log, type: .fault)
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Auth

    private func applyAuthHeaders(to request: inout URLRequest) {
        guard let snap = NotificationAuthShared.load() else {
            os_log("[ext] App Group unavailable suite=%{public}@ (check App Groups capability)", log: log, type: .fault, NotificationAuthShared.suiteName)
            return
        }

        let auth = snap.authTypeRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        os_log("[ext] authType=%{public}@ idLen=%{public}d secretLen=%{public}d bearerLen=%{public}d frigateLen=%{public}d",
               log: log, type: .info,
               auth,
               snap.cloudFlareClientId.count,
               snap.cloudFlareSecret.count,
               snap.jwtBearer.count,
               snap.jwtFrigate.count)

        switch auth {
        case "cloudflare":
            if !snap.cloudFlareClientId.isEmpty && !snap.cloudFlareSecret.isEmpty {
                request.setValue(snap.cloudFlareClientId, forHTTPHeaderField: "CF-Access-Client-Id")
                request.setValue(snap.cloudFlareSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
                os_log("[ext] Added Cloudflare Access headers", log: log, type: .info)
            } else {
                os_log("[ext] Cloudflare selected but CF creds empty", log: log, type: .fault)
            }

        case "bearer":
            let token = snap.jwtBearer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                request.setValue(normalizedBearer(token), forHTTPHeaderField: "Authorization")
                os_log("[ext] Added Authorization header (bearer)", log: log, type: .info)
            } else {
                os_log("[ext] Bearer selected but jwtBearer empty", log: log, type: .fault)
            }

        case "frigate":
            let token = snap.jwtFrigate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                request.setValue(normalizedBearer(token), forHTTPHeaderField: "Authorization")
                os_log("[ext] Added Authorization header (frigate)", log: log, type: .info)
            } else {
                os_log("[ext] Frigate selected but jwtFrigate empty", log: log, type: .fault)
            }

        default:
            os_log("[ext] No auth headers added (authType=%{public}@)", log: log, type: .info, auth)
        }
    }

    private func normalizedBearer(_ token: String) -> String {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.lowercased().hasPrefix("bearer ") { return t }
        return "Bearer \(t)"
    }
}
