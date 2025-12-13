//
//  NotificationService.swift
//  NotificationExtension
//

import UserNotifications
import Foundation
import OSLog

final class NotificationService: UNNotificationServiceExtension, URLSessionDelegate, URLSessionTaskDelegate {

    private let log = OSLog(subsystem: "NSE", category: "NSE")

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    // Turn off once you're done testing
    private let prefixTitleForDebug = false

    // Delegate-backed session so we can handle TLS challenges
    private lazy var imageSession: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 15
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    // MARK: - UNNotificationServiceExtension

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

        // Debug visibility (fault so you see it)
        let authRaw = NotificationAuthShared.load()?.authTypeRaw ?? "<nil>"
        os_log("[ext] authTypeRaw=%{public}@", log: log, type: .fault, authRaw)
        os_log("[ext] host=%{public}@ isLAN=%{public}d",
               log: log, type: .fault,
               url.host ?? "<nil>",
               isPrivateLANIPv4(url.host) ? 1 : 0)

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("image/*", forHTTPHeaderField: "Accept")

        applyAuthHeaders(to: &req)

        imageSession.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }

            if let e = error as? URLError {
                os_log("[ext] download URLError code=%{public}d", log: self.log, type: .fault, e.errorCode)
            }

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

    // MARK: - TLS challenge handling (self-signed for Frigate LAN only)

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        handleTLSChallenge(challenge, completionHandler: completionHandler)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        handleTLSChallenge(challenge, completionHandler: completionHandler)
    }

    private func handleTLSChallenge(
        _ challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        let authRaw = NotificationAuthShared.load()?.authTypeRaw ?? "none"

        let authNorm = authRaw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        let bypass = authNorm.contains("frigate") && isPrivateLANIPv4(host)

        os_log("[ext] TLS challenge host=%{public}@ bypass=%{public}d",
               log: log, type: .fault, host, bypass ? 1 : 0)

        if bypass {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    private func isPrivateLANIPv4(_ host: String?) -> Bool {
        guard let host else { return false }
        let parts = host.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }

        let a = parts[0], b = parts[1]
        if a == 10 { return true }
        if a == 192 && b == 168 { return true }
        if a == 172 && (16...31).contains(b) { return true }
        return false
    }

    // MARK: - Auth

    private func applyAuthHeaders(to request: inout URLRequest) {
        guard let snap = NotificationAuthShared.load() else {
            os_log("[ext] App Group unavailable suite=%{public}@ (check App Groups capability)", log: log, type: .fault, NotificationAuthShared.suiteName)
            return
        }

        let authNorm = snap.authTypeRaw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        os_log("[ext] authTypeNorm=%{public}@ idLen=%{public}d secretLen=%{public}d bearerLen=%{public}d frigateLen=%{public}d",
               log: log, type: .info,
               authNorm,
               snap.cloudFlareClientId.count,
               snap.cloudFlareSecret.count,
               snap.jwtBearer.count,
               snap.jwtFrigate.count)

        switch true {
        case authNorm.contains("cloudflare"):
            if !snap.cloudFlareClientId.isEmpty && !snap.cloudFlareSecret.isEmpty {
                request.setValue(snap.cloudFlareClientId, forHTTPHeaderField: "CF-Access-Client-Id")
                request.setValue(snap.cloudFlareSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
                os_log("[ext] Added Cloudflare Access headers", log: log, type: .info)
            } else {
                os_log("[ext] Cloudflare selected but CF creds empty", log: log, type: .fault)
            }

        case authNorm.contains("bearer"):
            let token = snap.jwtBearer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                request.setValue(normalizedBearer(token), forHTTPHeaderField: "Authorization")
                os_log("[ext] Added Authorization header (bearer)", log: log, type: .info)
            } else {
                os_log("[ext] Bearer selected but jwtBearer empty", log: log, type: .fault)
            }

        case authNorm.contains("frigate"):
            let token = snap.jwtFrigate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !token.isEmpty {
                request.setValue(normalizedBearer(token), forHTTPHeaderField: "Authorization")
                os_log("[ext] Added Authorization header (frigate)", log: log, type: .info)
            } else {
                os_log("[ext] Frigate selected but jwtFrigate empty", log: log, type: .fault)
            }

        default:
            os_log("[ext] No auth headers added (authTypeNorm=%{public}@)", log: log, type: .info, authNorm)
        }
    }

    private func normalizedBearer(_ token: String) -> String {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.lowercased().hasPrefix("bearer ") { return t }
        return "Bearer \(t)"
    }
}
