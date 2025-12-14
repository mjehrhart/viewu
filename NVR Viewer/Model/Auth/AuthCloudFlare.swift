//
//  AuthCloudFlare.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/3/25.
//  v1

import Foundation

private let CF_APP_GROUP_SUITE = "group.com.viewu.app"

final class AuthCloudFlare {

    static let _shared = AuthCloudFlare()
    static func shared() -> AuthCloudFlare { _shared }

    // Canonical keys (MUST match MQTTManager)
    private enum Keys {
        static let cloudFlareURLAddress    = "cloudFlareURLAddress"
        static let cloudFlareClientId      = "cloudFlareClientId"
        static let cloudFlareClientSecret  = "cloudFlareClientSecret"

        // Legacy (migration only)
        static let legacyCloudFlareSecret  = "cloudFlareSecret"
    }

    private let appGroupDefaults: UserDefaults
    private let standardDefaults: UserDefaults

    // Keep a single session like your logs indicate
    private let delegate = CloudflareAccessURLSessionDelegate()
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg, delegate: delegate, delegateQueue: nil)
    }()

    private init() {
        self.appGroupDefaults = UserDefaults(suiteName: CF_APP_GROUP_SUITE) ?? .standard
        self.standardDefaults = .standard
    }

    // MARK: - Public API (keeps your existing call pattern)

    func connectWithCloudflareAccess(
        host: String,
        endpoint: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        Log.debug(
            page: "AuthCloudFlare",
            fn: "connectWithCloudflareAccess",
            "Starting Cloudflare request. host=\(host), endpoint=\(endpoint)"
        )

        // 1) Ensure ClientId/Secret are consistent across STANDARD + APP GROUP
        //let creds = syncCloudflareCredsAcrossStores()
        let creds = CloudflareAccessCreds.getAndSync()


        // 2) Build the URL (supports either host+endpoint, or full URL in host when endpoint is empty)
        guard let urlString = buildURLString(host: host, endpoint: endpoint) else {
            let err = NSError(
                domain: "AuthCloudFlare",
                code: -1000,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Cloudflare URL (host/endpoint normalization failed)."]
            )
            Log.error(page: "AuthCloudFlare", fn: "connectWithCloudflareAccess", "URL build failed. host=\(host) endpoint=\(endpoint)")
            completion(nil, err)
            return
        }

        Log.debug(
            page: "AuthCloudFlare",
            fn: "connectWithCloudflareAccess",
            "Normalized URL components. trimmedHost=\(normalizedHostForLog(host)), normalizedEndpoint=\(endpoint), urlString=\(urlString)"
        )

        guard let url = URL(string: urlString) else {
            let err = NSError(
                domain: "AuthCloudFlare",
                code: -1001,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL string: \(urlString)"]
            )
            Log.error(page: "AuthCloudFlare", fn: "connectWithCloudflareAccess", "Invalid URL string: \(urlString)")
            completion(nil, err)
            return
        }

        // 3) Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        // Cloudflare Access headers (canonical)
        if !creds.clientId.isEmpty {
            request.setValue(creds.clientId, forHTTPHeaderField: "CF-Access-Client-Id")
        }
        if !creds.clientSecret.isEmpty {
            request.setValue(creds.clientSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
        }

        // Caller-provided headers
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }

        Log.debug(
            page: "AuthCloudFlare",
            fn: "connectWithCloudflareAccess",
            """
            Prepared request:
              URL=\(url.absoluteString)
              Method=\(method)
              CF-Access-Client-Id present=\(!creds.clientId.isEmpty)
              CF-Access-Client-Secret present=\(!creds.clientSecret.isEmpty)
            """
        )

        Log.debug(
            page: "AuthCloudFlare",
            fn: "connectWithCloudflareAccess",
            "Using shared URLSession with CloudflareAccessURLSessionDelegate. Starting dataTask."
        )

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                Log.error(
                    page: "AuthCloudFlare",
                    fn: "connectWithCloudflareAccess.dataTask",
                    "Network/transport error: \(error.localizedDescription)"
                )
                completion(nil, error)
                return
            }

            if let http = response as? HTTPURLResponse {
                Log.debug(
                    page: "AuthCloudFlare",
                    fn: "connectWithCloudflareAccess.dataTask",
                    "Received HTTP response. statusCode=\(http.statusCode), url=\(http.url?.absoluteString ?? "nil")"
                )
            }

            guard let data = data else {
                let err = NSError(
                    domain: "AuthCloudFlare",
                    code: -1002,
                    userInfo: [NSLocalizedDescriptionKey: "No data returned."]
                )
                Log.error(page: "AuthCloudFlare", fn: "connectWithCloudflareAccess.dataTask", "No data returned.")
                completion(nil, err)
                return
            }

            Log.debug(
                page: "AuthCloudFlare",
                fn: "connectWithCloudflareAccess.dataTask",
                "Cloudflare Access request succeeded. Data length=\(data.count) bytes."
            )
            completion(data, nil)
        }

        Log.debug(page: "AuthCloudFlare", fn: "connectWithCloudflareAccess", "dataTask.resume() called for URL=\(url.absoluteString)")
        task.resume()
    }

    // MARK: - Creds syncing (THIS is the “real fix” for matching MQTT + NVR)

    private struct CredsSnapshot {
        let clientId: String
        let clientSecret: String
        let source: String
    }

    /// Ensures the canonical keys `cloudFlareClientId` + `cloudFlareClientSecret`
    /// contain the same values in BOTH:
    /// - UserDefaults.standard (SwiftUI @AppStorage reads/writes here)
    /// - App Group suite (MQTTManager reads here)
    ///
    /// Rules:
    /// - Prefer APP GROUP when it has both values (MQTT already relies on it).
    /// - Otherwise fall back to STANDARD.
    /// - If secret is missing but legacy `cloudFlareSecret` exists, migrate it into `cloudFlareClientSecret`.
    /// - Never overwrite a non-empty value with an empty one.
    private func syncCloudflareCredsAcrossStores() -> CredsSnapshot {

        let stdId = (standardDefaults.string(forKey: Keys.cloudFlareClientId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var stdSecret = (standardDefaults.string(forKey: Keys.cloudFlareClientSecret) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let legacySecret = (standardDefaults.string(forKey: Keys.legacyCloudFlareSecret) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let agId = (appGroupDefaults.string(forKey: Keys.cloudFlareClientId) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let agSecret = (appGroupDefaults.string(forKey: Keys.cloudFlareClientSecret) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Migrate legacy secret into STANDARD canonical (only if canonical is empty)
        if stdSecret.isEmpty, !legacySecret.isEmpty {
            stdSecret = legacySecret
            standardDefaults.set(stdSecret, forKey: Keys.cloudFlareClientSecret)
            Log.debug(page: "AuthCloudFlare", fn: "syncCloudflareCredsAcrossStores", "Migrated legacy cloudFlareSecret -> cloudFlareClientSecret (standard)")
        }

        // Choose authoritative source
        let chosen: CredsSnapshot
        if !agId.isEmpty, !agSecret.isEmpty {
            chosen = CredsSnapshot(clientId: agId, clientSecret: agSecret, source: "appGroup")
        } else if !stdId.isEmpty, !stdSecret.isEmpty {
            chosen = CredsSnapshot(clientId: stdId, clientSecret: stdSecret, source: "standard")
        } else {
            chosen = CredsSnapshot(clientId: agId.isEmpty ? stdId : agId, clientSecret: agSecret.isEmpty ? stdSecret : agSecret, source: "partial/empty")
        }

        // Mirror into APP GROUP (for MQTT)
        if !chosen.clientId.isEmpty { appGroupDefaults.set(chosen.clientId, forKey: Keys.cloudFlareClientId) }
        if !chosen.clientSecret.isEmpty { appGroupDefaults.set(chosen.clientSecret, forKey: Keys.cloudFlareClientSecret) }

        // Mirror into STANDARD (for UI / NVRConfig consumers)
        if !chosen.clientId.isEmpty { standardDefaults.set(chosen.clientId, forKey: Keys.cloudFlareClientId) }
        if !chosen.clientSecret.isEmpty { standardDefaults.set(chosen.clientSecret, forKey: Keys.cloudFlareClientSecret) }

        Log.debug(
            page: "AuthCloudFlare",
            fn: "connectWithCloudflareAccess",
            "[app] Synced CF creds to App Group. idLen=\(chosen.clientId.count) secretLen=\(chosen.clientSecret.count)"
        )

        return chosen
    }

    // MARK: - URL normalization

    /// Returns a final URL string, handling two common cases:
    /// 1) host is a base like "frigate.example.com:443" and endpoint is "/api/config"
    /// 2) host is already a FULL URL (including path/query) and endpoint is empty
    private func buildURLString(host: String, endpoint: String) -> String? {
        let h = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        // Case 2: host is already the full URL
        if !h.isEmpty, e.isEmpty, let url = URL(string: h), url.scheme != nil {
            return url.absoluteString
        }

        // Case 1: combine host + endpoint
        // Allow host to be either "example.com", "https://example.com", "example.com:443", etc.
        guard !h.isEmpty else { return nil }

        // Normalize host into components (scheme + host + optional port)
        let hostURL: URL? = {
            if let u = URL(string: h), u.scheme != nil {
                return u
            }
            return URL(string: "https://\(h)")
        }()

        guard let parsed = hostURL else { return nil }

        // If host is malformed (e.g., "https://:443") this will have empty host; fail fast.
        if (parsed.host ?? "").isEmpty {
            return nil
        }

        // Ensure endpoint starts with "/"
        let endpointFixed: String = {
            if e.isEmpty { return "" }
            if e.hasPrefix("/") { return e }
            return "/" + e
        }()

        // Build final URL as: scheme://host:port + endpoint
        var comps = URLComponents()
        comps.scheme = parsed.scheme ?? "https"
        comps.host = parsed.host
        comps.port = parsed.port

        // Preserve endpoint query if it contains "?"
        if endpointFixed.contains("?") {
            let parts = endpointFixed.split(separator: "?", maxSplits: 1).map(String.init)
            comps.path = parts.first ?? ""
            comps.percentEncodedQuery = parts.count > 1 ? parts[1] : nil
        } else {
            comps.path = endpointFixed
        }

        return comps.url?.absoluteString
    }

    private func normalizedHostForLog(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - URLSession delegate

/// Keep this minimal and safe: default trust handling.
/// (If you already have a stricter/looser delegate elsewhere, do not duplicate this class.)
final class CloudflareAccessURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }
}
