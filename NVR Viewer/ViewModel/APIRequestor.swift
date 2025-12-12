//
//  APIRequestor.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/13/24.
//

import Foundation
import JWTKit

final class APIRequester: NSObject {
    
    // MARK: - Helpers

    /// Normalizes `base` + `endpoint` into a single URL:
    /// - trims a trailing "/" from base
    /// - ensures endpoint either starts with "/" or is empty
    private func makeURL(base: String, endpoint: String) -> URL? {
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base

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
                let error = NSError(
                    domain: "InvalidURL",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL in postImageToFrigatePlus: base=\(urlString), endpoint=\(endpoint)"]
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "postImageToFrigatePlus", error.localizedDescription
                )
                completion(nil, error)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, _, error in
                completion(data, error)
            }
            task.resume()

//            let fullURLString = urlString + endpoint
//            guard let url = URL(string: fullURLString) else {
//                Log.error(
//                    page: "APIRequestor",
//                    fn: "postImageToFrigatePlus", "Invalid URL: \(fullURLString)"
//                )
//                return
//            }
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            
//            let session = URLSession(
//                configuration: .default,
//                delegate: self,
//                delegateQueue: .main
//            )
//            
//            let task = session.dataTask(with: request) { data, _, error in
//                completion(data, error)
//            }
//            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWTFrigate() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "postImageToFrigatePlus", "Failed to generate Frigate JWT"
                )
                return
            }
            await connectToFrigateAPIWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: endpoint
            ) { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "postImageToFrigatePlus","Failed to generate bearer JWT"
                )
                return
            }
            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: endpoint
            ) { data, error in
                completion(data, error)
            }
            
        case .cloudflare:
            await connectWithCloudflareAccess(
                host: urlString,
                endpoint: endpoint
            ) { data, error in
                completion(data, error)
            }
            
        default:
            Log.error(
                page: "APIRequestor",
                fn: "postImageToFrigatePlus", "unsupported authType \(authType)"
            )
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
        
        // update background fetch timestamp
        let after = Int(Date().timeIntervalSince1970)
        UserDefaults.standard.set(String(after), forKey: "background_fetch_events_epochtime")
        
        await fetchNVREvents(
            urlString: urlString,
            endpoint: endpoint,
            authType: authType
        ) { data, error in
            
            // Transport / API error
            if let error = error {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchEventsInBackground", "Network/API error: \(error.localizedDescription)"
                )
                return
            }
            
            guard let data = data else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchEventsInBackground", "No data returned from fetchNVREvents"
                )
                return
            }
            
            do {
                let arrayEvents = try JSONDecoder().decode([NVRConfigurationHTTP].self, from: data)
                
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
                    fn: "fetchEventsInBackground", "JSON decode error: \(error)"
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
                let error = NSError(
                    domain: "InvalidURL",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL in fetchNVREvents: base=\(urlString), endpoint=\(endpoint)"]
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVREvents", error.localizedDescription
                )
                completion(nil, error)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, _, error in
                completion(data, error)
            }
            task.resume()

//            let urlStringEvents = urlString + endpoint
//            guard let url = URL(string: urlStringEvents) else {
//                Log.error(
//                    page: "APIRequestor",
//                    fn: "fetchNVREvents", "Invalid URL: \(urlStringEvents)"
//                )
//                return
//            }
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "GET"
//            
//            let session = URLSession(
//                configuration: .default,
//                delegate: self,
//                delegateQueue: .main
//            )
//            
//            let task = session.dataTask(with: request) { data, _, error in
//                completion(data, error)
//            }
//            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWTFrigate() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVREvents", "Failed to generate Frigate JWT"
                )
                return
            }
            await connectToFrigateAPIWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: endpoint
            ) { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVREvents", "Failed to generate bearer JWT"
                )
                return
            }
            // IMPORTANT: use `endpoint` (e.g. /api/events...) rather than hardcoding /api/config
            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: endpoint
            ) { data, error in
                completion(data, error)
            }
            
        case .cloudflare:
            // IMPORTANT: use `endpoint` here as well
            await connectWithCloudflareAccess(
                host: urlString,
                endpoint: endpoint
            ) { data, error in
                completion(data, error)
            }
            
        default:
            Log.error(
                page: "APIRequestor",
                fn: "fetchNVREvents", "unsupported authType \(authType)"
            )
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
                let error = NSError(
                    domain: "InvalidURL",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid image URL: \(urlString)"]
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage", error.localizedDescription
                )
                completion(nil, error)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    completion(nil, error)
                    return
                }

                if data.count < 50 {
                    do {
                        let decoded = try JSONDecoder().decode(FrigateResponse.self, from: data)
                        if decoded.success == false {
                            let errorTemp = NSError(
                                domain: "com.john.matthew",
                                code: 101,
                                userInfo: nil
                            )
                            completion(nil, errorTemp)
                            return
                        }
                    } catch {
                        Log.error(
                            page: "APIRequestor",
                            fn: "fetchImage", "\(error)"
                        )
                    }
                }

                completion(data, error)
            }
            task.resume()

//            guard let url = URL(string: urlString) else {
//                Log.error(
//                    page: "APIRequestor",
//                    fn: "fetchImage", "Invalid URL: \(urlString)"
//                )
//                return
//            }
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "GET"
//            
//            let session = URLSession(
//                configuration: .default,
//                delegate: self,
//                delegateQueue: .main
//            )
//            
//            let task = session.dataTask(with: request) { data, _, error in
//                guard let data = data else {
//                    completion(nil, error)
//                    return
//                }
//                
//                if data.count < 50 {
//                    do {
//                        let decoded = try JSONDecoder().decode(FrigateResponse.self, from: data)
//                        if decoded.success == false {
//                            let errorTemp = NSError(
//                                domain: "com.john.matthew",
//                                code: 101,
//                                userInfo: nil
//                            )
//                            completion(nil, errorTemp)
//                            return
//                        }
//                    } catch {
//                        Log.error(
//                            page: "APIRequestor",
//                            fn: "fetchImage", "\(error)"
//                        )
//                    }
//                }
//                
//                completion(data, error)
//            }
//            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWTFrigate() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage", "Failed to generate Frigate JWT"
                )
                return
            }
            await connectToFrigateAPIWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: ""
            ) { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchImage", "Failed to generate bearer JWT"
                )
                return
            }
            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: ""
            ) { data, error in
                completion(data, error)
            }
            
        case .cloudflare:
            await connectWithCloudflareAccess(
                host: urlString,
                endpoint: ""
            ) { data, error in
                completion(data, error)
            }
            
        default:
            Log.error(
                page: "APIRequestor",
                fn: "fetchImage", "unsupported authType \(authType)"
            )
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
                let error = NSError(
                    domain: "InvalidURL",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL in fetchNVRConfig: base=\(urlString)"]
                )
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVRConfig", error.localizedDescription
                )
                completion(nil, error)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, _, error in
                completion(data, error)
            }
            task.resume()

//            let fullURLString = "\(urlString)/api/config"
//            guard let url = URL(string: fullURLString) else {
//                Log.error(
//                    page: "APIRequestor",
//                    fn: "fetchNVRConfig", "Invalid URL: \(fullURLString)"
//                )
//                return
//            }
//            
//            var request = URLRequest(url: url)
//            request.httpMethod = "GET"
//            
//            let session = URLSession(
//                configuration: .default,
//                delegate: self,
//                delegateQueue: .main
//            )
//            
//            let task = session.dataTask(with: request) { data, _, error in
//                completion(data, error)
//            }
//            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWTFrigate() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVRConfig", "Failed to generate Frigate JWT"
                )
                return
            }
            await connectToFrigateAPIWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: "/api/config"
            ) { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                Log.error(
                    page: "APIRequestor",
                    fn: "fetchNVRConfig", "Failed to generate bearer JWT"
                )
                return
            }
            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: "/api/config"
            ) { data, error in
                completion(data, error)
            }
            
        case .cloudflare:
            await connectWithCloudflareAccess(
                host: urlString,
                endpoint: "/api/config"
            ) { data, error in
                completion(data, error)
            }
            
        default:
            Log.error(
                page: "APIRequestor",
                fn: "fetchNVRConfig", "unsupported authType \(authType)"
            )
        }
    }
    
    // MARK: - Connection check
    
    func checkConnectionStatus(
        urlString: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async throws {

        // Helper to build a simple NSError
        func makeError(_ message: String, code: Int = 500) -> NSError {
            NSError(
                domain: "connection.info",
                code: code,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        switch authType {
        case .none:
            guard let url = makeURL(base: urlString, endpoint: "/api/version") else {
                Log.error(
                    page: "APIRequestor",
                    fn: "checkConnectionStatus", "Invalid URL - base=\(urlString)"
                )
                return completion(nil, makeError("Invalid URL \(urlString)/api/version", code: 400))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, response, error in

                if let error = error {
                    Log.error(
                        page: "APIRequestor",
                        fn: "checkConnectionStatus", "\(error.localizedDescription)"
                    )
                    let errorTemp = makeError(
                        "Network error: \(error.localizedDescription) - \(url.absoluteString)"
                    )
                    return completion(nil, errorTemp)
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    Log.error(
                        page: "APIRequestor",
                        fn: "connection.info:invalid response", "Invalid Response - \(url.absoluteString)"
                    )
                    return completion(nil, makeError("Invalid HTTP response"))
                }

                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    Log.error(
                        page: "APIRequestor",
                        fn: "connection.info:statusCode",  "\(statusCode) - \(url.absoluteString)"
                    )
                    return completion(nil, makeError("HTTP \(statusCode)", code: statusCode))
                }

                guard let data = data, !data.isEmpty else {
                    Log.error(
                        page: "APIRequestor",
                        fn: "connection.info:dataEmpty", "DATA_EMPTY - \(url.absoluteString)"
                    )
                    return completion(nil, makeError("Empty response", code: 502))
                }

                if let firstByte = data.first {
                    let firstByteData = Data([firstByte])
                    if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                        let character = Character(firstCharacterString)
                        if !character.isWholeNumber {
                            Log.error(
                                page: "APIRequestor",
                                fn: "connection.info:notDigit", "NOT_WHOLE_NUMBER - \(url.absoluteString)"
                            )
                            return completion(nil, makeError("Unexpected response format", code: 501))
                        }
                    }
                }

                completion(data, nil)
            }

            task.resume()

//            let fullUrlString = urlString + "/api/version"
//            guard let url = URL(string: fullUrlString) else {
//                Log.error(
//                    page: "APIRequestor",
//                    fn: "checkConnectionStatus", "Invalid URL - \(fullUrlString)"
//                )
//                return completion(nil, makeError("Invalid URL \(fullUrlString)", code: 400))
//            }
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "GET"
//
//            let session = URLSession(
//                configuration: .default,
//                delegate: self,
//                delegateQueue: .main
//            )
//
//            let task = session.dataTask(with: request) { data, response, error in
//
//                if let error = error {
//                    Log.error(
//                        page: "APIRequestor",
//                        fn: "checkConnectionStatus", "\(error.localizedDescription)"
//                    )
//                    let errorTemp = makeError(
//                        "Network error: \(error.localizedDescription) - \(fullUrlString)"
//                    )
//                    return completion(nil, errorTemp)
//                }
//
//                guard let httpResponse = response as? HTTPURLResponse else {
//                    Log.error(
//                        page: "APIRequestor",
//                        fn: "connection.info:invalid response", "Invalid Response - \(fullUrlString)"
//                    )
//                    return completion(nil, makeError("Invalid HTTP response"))
//                }
//
//                let statusCode = httpResponse.statusCode
//                if statusCode != 200 {
//                    Log.error(
//                        page: "APIRequestor",
//                        fn: "connection.info:statusCode",  "\(statusCode) - \(fullUrlString)"
//                    )
//                    return completion(nil, makeError("HTTP \(statusCode)", code: statusCode))
//                }
//
//                // Validate first byte is a digit
//                guard let data = data, !data.isEmpty else {
//                    Log.error(
//                        page: "APIRequestor",
//                        fn: "connection.info:dataEmpty", "DATA_EMPTY - \(fullUrlString)"
//                    )
//                    return completion(nil, makeError("Empty response", code: 502))
//                }
//
//                if let firstByte = data.first {
//                    let firstByteData = Data([firstByte])
//                    if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
//                        let character = Character(firstCharacterString)
//                        if !character.isWholeNumber {
//                            Log.error(
//                                page: "APIRequestor",
//                                fn: "connection.info:notDigit", "NOT_WHOLE_NUMBER - \(fullUrlString)"
//                            )
//                            return completion(nil, makeError("Unexpected response format", code: 501))
//                        }
//                    }
//                }
//
//                completion(data, nil)
//            }
//
//            task.resume()

        case .frigate:
            guard let jwt = try? await generateJWTFrigate() else {
                return completion(nil, makeError("Failed to generate Frigate JWT", code: 503))
            }

            await connectToFrigateAPIWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: "/api/version"
            ) { data, error in

                if let error = error {
                    return completion(nil, error)
                }

                guard let data = data, !data.isEmpty else {
                    return completion(nil, makeError("Empty response", code: 500))
                }

                if let firstByte = data.first {
                    let firstByteData = Data([firstByte])
                    if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                        let character = Character(firstCharacterString)
                        if !character.isWholeNumber {
                            return completion(nil, makeError("Unexpected response format", code: 500))
                        }
                    }
                }

                return completion(data, nil)
            }

        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                return completion(nil, makeError("Failed to generate bearer JWT", code: 503))
            }

            await connectWithJWT(
                host: urlString,
                jwtToken: jwt,
                endpoint: "/api/version"
            ) { data, error in

                if let error = error {
                    return completion(nil, error)
                }

                guard let data = data, !data.isEmpty else {
                    return completion(nil, makeError("Empty response", code: 500))
                }

                if let firstByte = data.first {
                    let firstByteData = Data([firstByte])
                    if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                        let character = Character(firstCharacterString)
                        if !character.isWholeNumber {
                            return completion(nil, makeError("Unexpected response format", code: 500))
                        }
                    }
                }

                return completion(data, nil)
            }

        case .cloudflare:
            await connectWithCloudflareAccess(
                host: urlString,
                endpoint: "/api/version"
            ) { data, error in

                if let error = error {
                    return completion(nil, error)
                }

                guard let data = data, !data.isEmpty else {
                    return completion(nil, makeError("Empty response", code: 500))
                }

                if let firstByte = data.first {
                    let firstByteData = Data([firstByte])
                    if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                        let character = Character(firstCharacterString)
                        if !character.isWholeNumber {
                            return completion(nil, makeError("Unexpected response format", code: 500))
                        }
                    }
                }

                return completion(data, nil)
            }

        default:
            let fullUrlString = urlString + "/api/version"
            guard let url = URL(string: fullUrlString) else {
                Log.error(
                    page: "APIRequestor",
                    fn: "checkConnectionStatus", "AuthType is unsupported - \(fullUrlString)"
                )
                return completion(nil, makeError("Unsupported authType / invalid URL", code: 400))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let session = URLSession(
                configuration: .default,
                delegate: self,
                delegateQueue: .main
            )

            let task = session.dataTask(with: request) { data, response, error in

                if let error = error {
                    return completion(nil, error)
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion(nil, makeError("Invalid HTTP response"))
                }

                guard httpResponse.statusCode == 200 else {
                    return completion(nil, makeError("HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
                }

                guard let data = data, !data.isEmpty else {
                    return completion(nil, makeError("Empty response", code: 500))
                }

                printData(data)
                completion(data, nil)
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
                fn: "urlSession", err.localizedDescription
            )
        }
    }
}

// MARK: - Models

struct FrigateResponse: Codable {
    let message: String?
    let success: Bool?
}

