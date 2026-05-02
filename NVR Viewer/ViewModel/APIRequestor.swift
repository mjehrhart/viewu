/*
*  APIRequestor.swift
*  NVR Viewer
*
*  Performs authenticated and unauthenticated requests to the NVR and Frigate
*  APIs, including config, events, images, and connection checks.
*
*  Created by Matthew Ehrhart on 3/13/24.
*  Updated by CJ to use AuthFrigateLogin for Frigate login-based auth.
*
*/

import Foundation
import JWTKit

final class APIRequester: NSObject {

    // MARK: - Helpers

    /// Normalizes `base` + `endpoint` into a single URL:
    /// - trims whitespace
    /// - trims a trailing "/" from base
    /// - ensures endpoint either starts with "/" or is empty
    private func makeURL(base: String, endpoint: String) -> URL? {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let trimmedBase = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed

        let normalizedEndpoint: String
        if endpoint.isEmpty {
            normalizedEndpoint = ""
        } else if endpoint.hasPrefix("/") {
            normalizedEndpoint = endpoint
        } else {
            normalizedEndpoint = "/" + endpoint
        }

        return URL(string: trimmedBase + normalizedEndpoint)
    }

    /// Splits a fully-qualified URL into:
    /// - host/base   e.g. "https://example.local:8971"
    /// - endpoint    e.g. "/api/events/123/snapshot.jpg?download=1"
    ///
    /// This is useful for authenticated image requests where callers pass a full URL,
    /// but AuthFrigateLogin expects base host + endpoint separately.
    private func splitAbsoluteURL(_ absoluteString: String) -> (host: String, endpoint: String)? {
        let trimmed = absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let components = URLComponents(string: trimmed),
            let scheme = components.scheme,
            let host = components.host
        else {
            return nil
        }

        var base = "\(scheme)://\(host)"
        if let port = components.port {
            base += ":\(port)"
        }

        let path = components.percentEncodedPath
        let query = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        let endpoint = path + query

        return (host: base, endpoint: endpoint)
    }

    private func makeError(
        domain: String = "APIRequester",
        code: Int,
        message: String
    ) -> NSError {
        NSError(
            domain: domain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    private func finish(
        completion: @escaping (Data?, Error?) -> Void,
        data: Data?,
        error: Error?
    ) {
        if Thread.isMainThread {
            completion(data, error)
        } else {
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
    }

    private func performRequest(
        url: URL,
        method: String,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: .main
        )

        let task = session.dataTask(with: request) { data, _, error in
            defer { session.finishTasksAndInvalidate() }
            self.finish(completion: completion, data: data, error: error)
        }
        task.resume()
    }

    private func performImageRequest(
        url: URL,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: .main
        )

        let task = session.dataTask(with: request) { data, _, error in
            defer { session.finishTasksAndInvalidate() }

            guard let data = data else {
                self.finish(completion: completion, data: nil, error: error)
                return
            }

            if data.count < 50 {
                do {
                    let decoded = try JSONDecoder().decode(FrigateResponse.self, from: data)
                    if decoded.success == false {
                        let errorTemp = NSError(
                            domain: "com.john.matthew",
                            code: 101,
                            userInfo: [NSLocalizedDescriptionKey: decoded.message ?? "Frigate image request failed"]
                        )
                        self.finish(completion: completion, data: nil, error: errorTemp)
                        return
                    }
                } catch {
                    Log.error(
                        page: "APIRequestor",
                        fn: "fetchImage",
                        "\(error)"
                    )
                }
            }

            self.finish(completion: completion, data: data, error: error)
        }
        task.resume()
    }

    private func validateVersionPayload(
        data: Data?,
        error: Error?,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        if let error = error {
            finish(completion: completion, data: nil, error: error)
            return
        }

        guard let data = data, !data.isEmpty else {
            finish(
                completion: completion,
                data: nil,
                error: makeError(domain: "connection.info", code: 500, message: "Empty response")
            )
            return
        }

        if let firstByte = data.first {
            let firstByteData = Data([firstByte])
            if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                let character = Character(firstCharacterString)
                if !character.isWholeNumber {
                    finish(
                        completion: completion,
                        data: nil,
                        error: makeError(domain: "connection.info", code: 500, message: "Unexpected response format")
                    )
                    return
                }
            }
        }

        finish(completion: completion, data: data, error: nil)
    }

    // MARK: - Frigate Plus

    /// Posts an image to FrigatePlus. `eventId` is currently unused but kept to avoid breaking callers.
    func postImageToFrigatePlus(
        urlString: String,
        endpoint: String,
        eventId: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async {
        switch authType {
        case .none:
            guard let url = makeURL(base: urlString, endpoint: endpoint) else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid URL in postImageToFrigatePlus: base=\(urlString), endpoint=\(endpoint)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "postImageToFrigatePlus",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            performRequest(url: url, method: "POST", completion: completion)

        case .frigate:
            await AuthFrigateLogin.shared.connect(
                host: urlString,
                endpoint: endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                let error = makeError(
                    code: 503,
                    message: "Failed to generate bearer JWT"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "postImageToFrigatePlus",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .cloudflare:
            await AuthCloudFlare.shared().connectWithCloudflareAccess(
                host: urlString,
                endpoint: endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        default:
            let error = makeError(
                code: 400,
                message: "unsupported authType \(authType)"
            )
            Log.error(
                page: "APIRequestor",
                fn: "postImageToFrigatePlus",
                error.localizedDescription
            )
            finish(completion: completion, data: nil, error: error)
        }
    }

    // MARK: - Events (background fetch)

    func fetchEventsInBackground(
        urlString: String,
        backgroundFetchEventsEpochtime: String,
        epsType: String,
        authType: AuthType
    ) async {

        let endpoint = "/api/events?limit=10000&after=\(backgroundFetchEventsEpochtime)"
        let nextAfter = Int(Date().timeIntervalSince1970)

        await fetchNVREvents(
            urlString: urlString,
            endpoint: endpoint,
            authType: authType
        ) { data, error in

            if let error = error {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchEventsInBackground",
                    "Network/API error: \(error.localizedDescription)"
                )
                return
            }

            guard let data = data else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchEventsInBackground",
                    "No data returned from fetchNVREvents"
                )
                return
            }

            do {
                let arrayEvents = try JSONDecoder().decode([NVRConfigurationHTTP].self, from: data)

                // Only advance the cursor after a successful fetch/decode.
                UserDefaults.standard.set(
                    String(nextAfter),
                    forKey: "background_fetch_events_epochtime"
                )

                if arrayEvents.isEmpty {
                    Log.debug(
                        page: "APIRequestor",
                        fn: "fetchEventsInBackground",
                        "No new events returned from \(endpoint)"
                    )
                } else {
                    Log.debug(
                        page: "APIRequestor",
                        fn: "fetchEventsInBackground",
                        "Decoded \(arrayEvents.count) events from \(endpoint)"
                    )
                }

                for event in arrayEvents {
                    let url = urlString
                    let id = event.id
                    let frameTime = event.start_time

                    var enteredZones = ""
                    for zone in event.zones ?? [] {
                        enteredZones += zone + "|"
                    }

                    var eps = EndpointOptions()
                    eps.snapshot       = url + "/api/events/\(id)/snapshot.jpg"
                    eps.cameraName     = event.camera
                    eps.m3u8           = url + "/vod/event/\(id)/master.m3u8"
                    eps.mp4            = url + "/api/events/\(id)/clip.mp4"
                    eps.frameTime      = frameTime
                    eps.label          = event.label
                    eps.id             = id
                    eps.thumbnail      = url + "/api/events/\(id)/thumbnail.jpg"
                    eps.camera         = url + "/cameras/\(event.camera)"
                    eps.debug          = url + "/api/\(event.camera)?h=480"
                    eps.image          = url + "/api/\(event.camera)/recordings/\(frameTime)/snapshot.png"
                    eps.score          = 0.0
                    eps.transportType  = "viewu"
                    eps.type           = epsType
                    eps.currentZones   = ""
                    eps.enteredZones   = enteredZones
                    eps.sublabel       = event.sub_label

                    // normalize optionals to non-nil strings
                    if eps.sublabel == nil      { eps.sublabel      = "" }
                    if eps.currentZones == nil  { eps.currentZones  = "" }
                    if eps.enteredZones == nil  { eps.enteredZones  = "" }

                    _ = EventStorage.shared.insertOrUpdate(
                        id: eps.id!,
                        frameTime: eps.frameTime!,
                        score: eps.score!,
                        type: eps.type!,
                        cameraName: eps.cameraName!,
                        label: eps.label!,
                        thumbnail: eps.thumbnail!,
                        snapshot: eps.snapshot!,
                        m3u8: eps.m3u8!,
                        mp4: eps.mp4!,
                        camera: eps.camera!,
                        debug: eps.debug!,
                        image: eps.image!,
                        transportType: eps.transportType!,
                        subLabel: eps.sublabel!,
                        currentZones: eps.currentZones!,
                        enteredZones: eps.enteredZones!
                    )
                }
            } catch {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchEventsInBackground",
                    "JSON decode error: \(error)"
                )
            }
        }
    }

    /// Low-level events fetcher used by background logic and potentially others.
    func fetchNVREvents(
        urlString: String,
        endpoint: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async {
        switch authType {
        case .none:
            guard let url = makeURL(base: urlString, endpoint: endpoint) else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid URL in fetchNVREvents: base=\(urlString), endpoint=\(endpoint)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVREvents",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            performRequest(url: url, method: "GET", completion: completion)

        case .frigate:
            await AuthFrigateLogin.shared.connect(
                host: urlString,
                endpoint: endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                let error = makeError(
                    code: 503,
                    message: "Failed to generate bearer JWT"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVREvents",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .cloudflare:
            await AuthCloudFlare.shared().connectWithCloudflareAccess(
                host: urlString,
                endpoint: endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        default:
            let error = makeError(
                code: 400,
                message: "unsupported authType \(authType)"
            )
            Log.error(
                page: "APIRequestor",
                fn: "fetchNVREvents",
                error.localizedDescription
            )
            finish(completion: completion, data: nil, error: error)
        }
    }

    // MARK: - Images

    func fetchImage(
        urlString: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async {
        switch authType {
        case .none:
            guard let url = URL(string: urlString) else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid image URL: \(urlString)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            performImageRequest(url: url, completion: completion)

        case .frigate:
            guard let target = splitAbsoluteURL(urlString) else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid image URL for Frigate auth: \(urlString)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            await AuthFrigateLogin.shared.connect(
                host: target.host,
                endpoint: target.endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                let error = makeError(
                    code: 503,
                    message: "Failed to generate bearer JWT"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            guard let target = splitAbsoluteURL(urlString) else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid image URL for bearer auth: \(urlString)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            await connectWithJWT(
                host: target.host,
                jwtToken: jwt,
                endpoint: target.endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .cloudflare:
            guard let target = splitAbsoluteURL(urlString) else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid image URL for Cloudflare auth: \(urlString)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            await AuthCloudFlare.shared().connectWithCloudflareAccess(
                host: target.host,
                endpoint: target.endpoint
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        default:
            let error = makeError(
                code: 400,
                message: "unsupported authType \(authType)"
            )
            Log.error(
                page: "APIRequestor",
                fn: "fetchImage",
                error.localizedDescription
            )
            finish(completion: completion, data: nil, error: error)
        }
    }

    // MARK: - Config

    func fetchNVRConfig(
        urlString: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async {
        switch authType {
        case .none:
            guard let url = makeURL(base: urlString, endpoint: "/api/config") else {
                let error = makeError(
                    domain: "InvalidURL",
                    code: 0,
                    message: "Invalid URL in fetchNVRConfig: base=\(urlString)"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVRConfig",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            performRequest(url: url, method: "GET", completion: completion)

        case .frigate:
            await AuthFrigateLogin.shared.connect(
                host: urlString,
                endpoint: "/api/config"
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                let error = makeError(
                    code: 503,
                    message: "Failed to generate bearer JWT"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVRConfig",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: "/api/config"
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        case .cloudflare:
            await AuthCloudFlare.shared().connectWithCloudflareAccess(
                host: urlString,
                endpoint: "/api/config"
            ) { data, error in
                self.finish(completion: completion, data: data, error: error)
            }

        default:
            let error = makeError(
                code: 400,
                message: "unsupported authType \(authType)"
            )
            Log.error(
                page: "APIRequestor",
                fn: "fetchNVRConfig",
                error.localizedDescription
            )
            finish(completion: completion, data: nil, error: error)
        }
    }

    // MARK: - Connection check

    func checkConnectionStatus(
        urlString: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async throws {

        switch authType {
        case .none:
            guard let url = makeURL(base: urlString, endpoint: "/api/version") else {
                let error = makeError(
                    domain: "connection.info",
                    code: 400,
                    message: "Invalid URL \(urlString)/api/version"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "checkConnectionStatus",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, response, error in
                defer { session.finishTasksAndInvalidate() }

                if let error = error {
                    Log.error(
                        page: "APIRequestor",
                        fn: "checkConnectionStatus",
                        error.localizedDescription
                    )
                    let errorTemp = self.makeError(
                        domain: "connection.info",
                        code: 500,
                        message: "Network error: \(error.localizedDescription) - \(url.absoluteString)"
                    )
                    self.finish(completion: completion, data: nil, error: errorTemp)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    Log.error(
                        page: "APIRequestor",
                        fn: "connection.info:invalid response",
                        "Invalid Response - \(url.absoluteString)"
                    )
                    self.finish(
                        completion: completion,
                        data: nil,
                        error: self.makeError(domain: "connection.info", code: 500, message: "Invalid HTTP response")
                    )
                    return
                }

                let statusCode = httpResponse.statusCode
                guard statusCode == 200 else {
                    Log.error(
                        page: "APIRequestor",
                        fn: "connection.info:statusCode",
                        "\(statusCode) - \(url.absoluteString)"
                    )
                    self.finish(
                        completion: completion,
                        data: nil,
                        error: self.makeError(domain: "connection.info", code: statusCode, message: "HTTP \(statusCode)")
                    )
                    return
                }

                self.validateVersionPayload(
                    data: data,
                    error: nil,
                    completion: completion
                )
            }

            task.resume()

        case .frigate:
            await AuthFrigateLogin.shared.connect(
                host: urlString,
                endpoint: "/api/version"
            ) { data, error in
                self.validateVersionPayload(
                    data: data,
                    error: error,
                    completion: completion
                )
            }

        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                finish(
                    completion: completion,
                    data: nil,
                    error: makeError(
                        domain: "connection.info",
                        code: 503,
                        message: "Failed to generate bearer JWT"
                    )
                )
                return
            }

            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: "/api/version"
            ) { data, error in
                self.validateVersionPayload(
                    data: data,
                    error: error,
                    completion: completion
                )
            }

        case .cloudflare:
            await AuthCloudFlare.shared().connectWithCloudflareAccess(
                host: urlString,
                endpoint: "/api/version"
            ) { data, error in
                self.validateVersionPayload(
                    data: data,
                    error: error,
                    completion: completion
                )
            }

        default:
            guard let url = makeURL(base: urlString, endpoint: "/api/version") else {
                let error = makeError(
                    domain: "connection.info",
                    code: 400,
                    message: "Unsupported authType / invalid URL"
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "checkConnectionStatus",
                    error.localizedDescription
                )
                finish(completion: completion, data: nil, error: error)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, response, error in
                defer { session.finishTasksAndInvalidate() }

                if let error = error {
                    self.finish(completion: completion, data: nil, error: error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.finish(
                        completion: completion,
                        data: nil,
                        error: self.makeError(domain: "connection.info", code: 500, message: "Invalid HTTP response")
                    )
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    self.finish(
                        completion: completion,
                        data: nil,
                        error: self.makeError(
                            domain: "connection.info",
                            code: httpResponse.statusCode,
                            message: "HTTP \(httpResponse.statusCode)"
                        )
                    )
                    return
                }

                self.validateVersionPayload(
                    data: data,
                    error: nil,
                    completion: completion
                )
            }
            task.resume()
        }
    }
}

// MARK: - URLSessionDelegate

extension APIRequester: URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Trust the HTTPS server (self-signed) if we have a serverTrust
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let err = error {
            Log.error(
                page: "APIRequestor",
                fn: "urlSession",
                err.localizedDescription
            )
        }
    }
}

// MARK: - Models

struct FrigateResponse: Codable {
    let message: String?
    let success: Bool?
}