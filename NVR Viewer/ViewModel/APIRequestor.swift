import Foundation
import JWTKit

class APIRequester: NSObject {
    
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
            let fullURLString = urlString + endpoint
            guard let url = URL(string: fullURLString) else {
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let session = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: .main)
            
            let task = session.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    completion(nil, error)
                    return
                }
                completion(data, error)
            }
            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWT() else {
                return
            }
            await connectToFrigateAPIWithJWT(host: urlString,
                                             jwtToken: jwt,
                                             endpoint: endpoint) { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                return
            }
            await connectWithJWT(host: urlString,
                                 jwtToken: jwt,
                                 endpoint: endpoint) { data, error in
                completion(data, error)
            }
            
        default:
            print("postImageToFrigatePlus: unsupported authType \(authType)")
        }
    }
    
    // MARK: - Events
    
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
        
        await fetchNVREvents(urlString: urlString,
                             endpoint: endpoint,
                             authType: authType) { data, error in
            guard let data = data else { return }
            
            do {
                let arrayEvents = try JSONDecoder().decode([NVRConfigurationHTTP].self, from: data)
                
                for event in arrayEvents {
                    let url = urlString
                    let id = event.id
                    let frameTime = event.start_time
                    
                    var enteredZones = ""
                    for zone in event.zones ?? [] {
                        enteredZones += zone + "|"
                    }
                    
                    var eps = EndpointOptions()
                    eps.snapshot    = url + "/api/events/\(id)/snapshot.jpg"
                    eps.cameraName  = event.camera
                    eps.m3u8        = url + "/vod/event/\(id)/master.m3u8"
                    eps.mp4         = url + "/api/events/\(id)/clip.mp4"
                    eps.frameTime   = event.start_time
                    eps.label       = event.label
                    eps.id          = event.id
                    eps.thumbnail   = url + "/api/events/\(id)/thumbnail.jpg"
                    eps.camera      = url + "/cameras/\(event.camera)"
                    eps.debug       = url + "/api/\(event.camera)?h=480"
                    eps.image       = url + "/api/\(event.camera)/recordings/\(frameTime)/snapshot.png"
                    eps.score       = 0.0
                    eps.transportType = "viewu"
                    eps.type        = epsType
                    eps.currentZones = ""
                    eps.enteredZones = enteredZones
                    eps.sublabel    = event.sub_label
                    
                    // normalize optionals to non-nil strings
                    if eps.sublabel == nil {
                        eps.sublabel = ""
                    }
                    if eps.currentZones == nil {
                        eps.currentZones = ""
                    }
                    if eps.enteredZones == nil {
                        eps.enteredZones = ""
                    }
                    
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
                Log.shared().print(page: "APIRequestor",
                                   fn: "fetchEventsInBackground",
                                   type: "ERROR",
                                   text: "\(error)")
            }
        }
    }
    
    func fetchNVREvents(
        urlString: String,
        endpoint: String,
        authType: AuthType,
        completion: @escaping (Data?, Error?) -> Void
    ) async {
        switch authType {
        case .none:
            let urlStringEvents = urlString + endpoint
            guard let url = URL(string: urlStringEvents) else {
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: .main)
            
            let task = session.dataTask(with: request) { data, _, error in
                completion(data, error)
            }
            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWT() else {
                return
            }
            await connectToFrigateAPIWithJWT(host: urlString,
                                             jwtToken: jwt,
                                             endpoint: endpoint) { data, error in
                completion(data, error)
            }
            
        case .bearer:
            // NOTE: this currently hardcodes "/api/config" instead of `endpoint`.
            guard let jwt = try? await generateJWTBearer() else {
                return
            }
            await connectWithJWT(host: urlString,
                                 jwtToken: jwt,
                                 endpoint: "/api/config") { data, error in
                completion(data, error)
            }
            
        default:
            print("fetchNVREvents: unsupported authType \(authType)")
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
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: .main)
            
            let task = session.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    completion(nil, error)
                    return
                }
                
                if data.count < 50 {
                    do {
                        let decoded = try JSONDecoder().decode(FrigateResponse.self, from: data)
                        if decoded.success == false {
                            let errorTemp = NSError(domain: "com.john.matthew", code: 101, userInfo: nil)
                            completion(nil, errorTemp)
                            return
                        }
                    } catch {
                        print("Error decoding FrigateResponse - 1001.a: \(error)")
                    }
                }
                
                completion(data, error)
            }
            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWT() else {
                return
            }
            await connectToFrigateAPIWithJWT(host: urlString,
                                             jwtToken: jwt,
                                             endpoint: "") { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                return
            }
            await connectWithJWT(host: urlString,
                                 jwtToken: jwt,
                                 endpoint: "") { data, error in
                completion(data, error)
            }
            
        default:
            print("fetchImage: unsupported authType \(authType)")
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
            let fullURLString = "\(urlString)/api/config"
            guard let url = URL(string: fullURLString) else {
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: .main)
            
            let task = session.dataTask(with: request) { data, _, error in
                completion(data, error)
            }
            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWT() else {
                return
            }
            await connectToFrigateAPIWithJWT(host: urlString,
                                             jwtToken: jwt,
                                             endpoint: "/api/config") { data, error in
                completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else {
                return
            }
            await connectWithJWT(host: urlString,
                                 jwtToken: jwt,
                                 endpoint: "/api/config") { data, error in
                completion(data, error)
            }
            
        default:
            print("fetchNVRConfig: unsupported authType \(authType)")
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
            let fullUrlString = urlString + "/api/version"
            guard let url = URL(string: fullUrlString) else {
                Log.shared().print(page: "APIRequestor",
                                   fn: "checkConnectionStatus",
                                   type: "ERROR",
                                   text: "Invalid URL - \(fullUrlString)")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: .main)
            
            let task = session.dataTask(with: request) { data, response, error in
                
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    let errorTemp = NSError(
                        domain: "connection.info:\(error.localizedDescription) - \(fullUrlString)",
                        code: 500,
                        userInfo: nil
                    )
                    return completion(nil, errorTemp)
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    Log.shared().print(page: "APIRequestor",
                                       fn: "connection.info:invalid response",
                                       type: "ERROR",
                                       text: "Invalid Response - \(fullUrlString)")
                    let errorTemp = NSError(
                        domain: "connection.info:invalid response",
                        code: 500,
                        userInfo: nil
                    )
                    return completion(nil, errorTemp)
                }
                
                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    Log.shared().print(page: "APIRequestor",
                                       fn: "connection.info:statusCode",
                                       type: "ERROR",
                                       text: "\(statusCode) - \(fullUrlString)")
                    let errorTemp = NSError(
                        domain: "connection.info:statusCode",
                        code: 500,
                        userInfo: nil
                    )
                    return completion(nil, errorTemp)
                }
                
                // Validate first byte is a digit (version should start with 0–9)
                if let firstByteData = data?.first.map({ Data([$0]) }),
                   let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                    
                    let character = Character(firstCharacterString)
                    if !character.isWholeNumber {
                        Log.shared().print(page: "APIRequestor",
                                           fn: "connection.info:statusCode",
                                           type: "ERROR",
                                           text: "NOT_WHOLE_NUMBER - \(fullUrlString)")
                        let errorTemp = NSError(domain: "connection.info", code: 501, userInfo: nil)
                        return completion(nil, errorTemp)
                    }
                }
                
                if data?.isEmpty ?? true {
                    Log.shared().print(page: "APIRequestor",
                                       fn: "connection.info:statusCode",
                                       type: "ERROR",
                                       text: "DATA_EMPTY - \(fullUrlString)")
                    let errorTemp = NSError(domain: "connection.info", code: 502, userInfo: nil)
                    return completion(nil, errorTemp)
                }
                
                completion(data, error)
            }
            
            task.resume()
            
        case .frigate:
            guard let jwt = try? await generateJWT() else { return }
            
            await connectToFrigateAPIWithJWT(host: urlString,
                                             jwtToken: jwt,
                                             endpoint: "/api/version") { data, error in
                
                if let firstByteData = data?.first.map({ Data([$0]) }),
                   let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                    
                    let character = Character(firstCharacterString)
                    if !character.isWholeNumber {
                        let errorTemp = NSError(domain: "", code: 500, userInfo: nil)
                        return completion(nil, errorTemp)
                    }
                }
                
                if data?.isEmpty ?? true {
                    let errorTemp = NSError(domain: "", code: 500, userInfo: nil)
                    return completion(nil, errorTemp)
                }
                
                return completion(data, error)
            }
            
        case .bearer:
            guard let jwt = try? await generateJWTBearer() else { return }
            
            await connectWithJWT(host: urlString,
                                 jwtToken: jwt,
                                 endpoint: "/api/version") { data, error in
                
                if let firstByteData = data?.first.map({ Data([$0]) }),
                   let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
                    
                    let character = Character(firstCharacterString)
                    if !character.isWholeNumber {
                        let errorTemp = NSError(domain: "", code: 500, userInfo: nil)
                        return completion(nil, errorTemp)
                    }
                }
                
                if data?.isEmpty ?? true {
                    let errorTemp = NSError(domain: "", code: 500, userInfo: nil)
                    return completion(nil, errorTemp)
                }
                
                return completion(data, error)
            }
            
        default:
            print("APIRequestor: checkConnectionStatus: AuthType is unsupported")
            let fullURLString = urlString + "/api/version"
            guard let url = URL(string: fullURLString) else {
                Log.shared().print(page: "APIRequestor",
                                   fn: "checkConnectionStatus",
                                   type: "ERROR",
                                   text: "")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let session = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: .main)
            
            let task = session.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        let errorTemp = NSError(domain: "",
                                                code: httpResponse.statusCode,
                                                userInfo: nil)
                        return completion(nil, errorTemp)
                    }
                } else {
                    let errorTemp = NSError(domain: "", code: 500, userInfo: nil)
                    return completion(nil, errorTemp)
                }
                
                printData(data ?? "NO DATA FOUND".data(using: .utf8)!)
                completion(data, error)
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
            print("Error APIRequestor urlSession: \(err.localizedDescription)")
            Log.shared().print(page: "APIRequestor",
                               fn: "urlSession",
                               type: "ERROR",
                               text: err.localizedDescription)
        }
    }
}

struct FrigateResponse: Codable {
    let message: String?
    let success: Bool?
}



// MARK: - Remove////
////  APIRequestor.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/13/24.
////
//
//import Foundation
//import JWTKit
// 
//class APIRequester: NSObject {
//    
//    func postImageToFrigatePlus(urlString: String, endpoint: String, eventId: String, authType: AuthType, completion: @escaping (Data?, Error?) -> Void) async {
//        
//        if let concreteAuthType = authType as? AuthType {
//            
//            switch concreteAuthType {
//            case .none:
//                
//                let urlString = urlString + endpoint
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                var request = URLRequest(url: url)
//                request.httpMethod = "POST"
//                
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//                let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//                    
//                    guard let data = data else { return }
//                    
//                    completion(data, error)
//                }
//                task.progress.resume()
//            case .frigate:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWT()
//                await connectToFrigateAPIWithJWT(host: urlString, jwtToken: jwt!, endpoint: endpoint){ data, error in
//                    completion(data, error)
//                }
//            case .bearer:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWTBearer()
//                await connectWithJWT(host: urlString, jwtToken: jwt!, endpoint: endpoint){ data, error in
//                    completion(data, error)
//                }
//            default :
//                print("do nothing for now")
//            }
//        }
//    }
//    
//    func fetchEventsInBackground(urlString: String, backgroundFetchEventsEpochtime: String, epsType: String, authType: AuthType) async{
//         
//        //DispatchQueue.main.async { [self] in
//            
//            let endpoint = "/api/events?limit=10000&after=\(backgroundFetchEventsEpochtime)"
//            let urlStringEvents = urlString + endpoint
//            
//            let after = Int(Date().timeIntervalSince1970)
//            //backgroundFetchEventsEpochtime = String(after)
//            UserDefaults.standard.set(String(after), forKey: "background_fetch_events_epochtime")
//            
//            
//            await fetchNVREvents(urlString: urlString, endpoint: endpoint, authType: authType) { data, error in
//                
//                guard let data = data else { return }
//                
//                do{
//                    let arrayEvents = try JSONDecoder().decode([NVRConfigurationHTTP].self, from: data)
//                    
//                    for event in arrayEvents {
//                        
//                        let url = urlString //self.nvr.getUrl()
//                        let id = event.id
//                        let frameTime = event.start_time
//                        
//                        var enteredZones = ""
//                        for zone in event.zones! {
//                            enteredZones += zone + "|"
//                        }
//                        
//                        var eps = EndpointOptions()
//                        eps.snapshot = url + "/api/events/\(id)/snapshot.jpg" //?bbox=1"
//                        eps.cameraName = event.camera
//                        eps.m3u8 = url + "/vod/event/\(id)/master.m3u8"
//                        eps.mp4 = url + "/api/events/\(id)/clip.mp4"
//                        eps.frameTime = event.start_time
//                        eps.label = event.label
//                        eps.id = event.id
//                        eps.thumbnail = url + "/api/events/\(id)/thumbnail.jpg"
//                        eps.camera = url + "/cameras/\(event.camera)"
//                        eps.debug = url + "/api/\(event.camera)?h=480"
//                        eps.image = url + "/api/\(event.camera)/recordings/\(frameTime)/snapshot.png"
//                        eps.score = 0.0
//                        eps.transportType = "viewu"
//                        eps.type = epsType
//                        eps.currentZones = ""
//                        eps.enteredZones = enteredZones
//                        eps.sublabel = event.sub_label
//                        
//                        //Check if value is nil
//                        if eps.sublabel == nil {
//                            eps.sublabel = ""
//                        }
//                        if eps.currentZones == nil {
//                            eps.currentZones = ""
//                        }
//                        if eps.enteredZones == nil {
//                            eps.enteredZones = ""
//                        }
//                        
//                        let _ = EventStorage.shared.insertOrUpdate(
//                            id: eps.id!,
//                            frameTime: eps.frameTime!,
//                            score: eps.score!,
//                            type: eps.type!,
//                            cameraName: eps.cameraName!,
//                            label: eps.label!,
//                            thumbnail: eps.thumbnail!,
//                            snapshot: eps.snapshot!,
//                            m3u8: eps.m3u8!,
//                            mp4: eps.mp4!,
//                            camera: eps.camera!,
//                            debug: eps.debug!,
//                            image: eps.image!,
//                            transportType: eps.transportType!,
//                            subLabel: eps.sublabel!, //ADDED 5/26 ?? "" TODO !
//                            currentZones: eps.currentZones!,
//                            enteredZones: eps.enteredZones!
//                        )
//                        
//                    }
//                } catch(let err) {
//                    Log.shared().print(page: "APIRequestor", fn: "fetchEventsInBackground", type: "ERROR", text: "\(err)")
//                }
//            }
//        //}
//    }
//    
//    func fetchNVREvents(urlString: String, endpoint: String, authType: AuthType, completion: @escaping (Data?, Error?) -> Void) async {
//        
//        if let concreteAuthType = authType as? AuthType {
//            
//            switch concreteAuthType {
//            case .none:
//                
//                let urlStringEvents = urlString + endpoint
//                guard let url = URL(string: urlStringEvents) else {
//                    return
//                }
//                 
//                var request = URLRequest(url: url)
//                request.httpMethod = "GET"
//                
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//                let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//                    
//                    completion(data, error)
//                }
//                task.progress.resume()
//            case .frigate:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWT()
//                await connectToFrigateAPIWithJWT(host: urlString, jwtToken: jwt!, endpoint: endpoint){ data, error in
//                    completion(data, error)
//                }
//            case .bearer:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWTBearer()
//                await connectWithJWT(host: urlString, jwtToken: jwt!, endpoint: "/api/config"){ data, error in
//                    completion(data, error)
//                }
//            default :
//                print("do nothing for now")
//            }
//        }
//    }
//    
//    func fetchImage(urlString: String, authType: AuthType, completion: @escaping (Data?, Error?) -> Void) async {
//        
//        if let concreteAuthType = authType as? AuthType {
//            
//            switch concreteAuthType {
//            case .none:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                var request = URLRequest(url: url)
//                request.httpMethod = "GET"
//                
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//                let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//                     
//                    guard let data = data else { return }
//                    
//                    if(data.count < 50){
//                        do {
//                            let de = try JSONDecoder().decode(FrigateResponse.self, from: data)
//                            if de.success! == false {
//                                let errorTemp = NSError(domain:"com.john.matthew", code: 101,  userInfo:nil)
//                                completion(nil, errorTemp)
//                                return
//                            }
//                        }catch{
//                            print("Error Message goes here - 1001.a")
//                        }
//                    }
//                    completion(data, error)
//                }
//                task.progress.resume()
//            case .frigate:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWT()
//                await connectToFrigateAPIWithJWT(host: urlString, jwtToken: jwt!, endpoint: ""){ data, error in
//                    completion(data, error)
//                }
//            case .bearer:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWTBearer()
//                await connectWithJWT(host: urlString, jwtToken: jwt!, endpoint: ""){ data, error in
//                    completion(data, error)
//                }
//            default :
//                print("do nothing for now")
//            }
//        }
//    }
//    
//    func fetchNVRConfig(urlString: String, authType: AuthType, completion: @escaping (Data?, Error?) -> Void) async  {
//        
//        if let concreteAuthType = authType as? AuthType {
//            
//            switch concreteAuthType {
//            case .none:
//                
//                let fullURLString = "\(urlString)/api/config"
//                guard let url = URL(string: fullURLString) else {
//                    return
//                }
//                
//                var request = URLRequest(url: url)
//                request.httpMethod = "GET"
//                
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//                let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//                    
//                    completion(data, error)
//                }
//                task.progress.resume()
//            case .frigate:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWT()
//                await connectToFrigateAPIWithJWT(host: urlString, jwtToken: jwt!, endpoint: "/api/config"){ data, error in
//                     
//                    completion(data, error)
//                }
//            case .bearer:
//                
//                guard let url = URL(string: urlString) else {
//                    return
//                }
//                
//                let jwt = try? await generateJWTBearer()
//                await connectWithJWT(host: urlString, jwtToken: jwt!, endpoint: "/api/config"){ data, error in
//                    completion(data, error)
//                }
//            default :
//                print("do nothing for now")
//            }
//        }
//    }
//
//    func checkConnectionStatus(urlString: String, authType: AuthType, completion: @escaping (Data?, Error?) -> Void) async throws {
//        
////        print("APIRequestor: checkConnectionStatus")
////        print("\(urlString)")
////        print("")
// 
//        if let concreteAuthType = authType as? AuthType {
//            
//            switch concreteAuthType {
//            case .none:
//                
//                let fullUrlString = urlString + "/api/version"
//                guard let url = URL(string: "\(fullUrlString)") else {
//                    Log.shared().print(page: "APIRequestor", fn: "checkConnectionStatus", type: "ERROR", text: "")
//                    return
//                }
//                
//                var request = URLRequest(url: url)
//                request.httpMethod = "GET"
//                
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//                let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//                      
//                    if let error = error {
//                            print("Error: \(error.localizedDescription)")
//                        let errorTemp = NSError(domain:"connection.info:\(error.localizedDescription)", code:500, userInfo:nil)
//                        return completion(nil, errorTemp )
//                        }
//                    
//                    guard let httpResponse = response as? HTTPURLResponse else {
//                        Log.shared().print(page: "APIRequestor", fn: "connection.info:invalid response", type: "ERROR", text: "")
//                        let errorTemp = NSError(domain:"connection.info:invalid response", code:500, userInfo:nil)
//                        return completion(nil, errorTemp )
//                    }
//
//                    let statusCode = httpResponse.statusCode
//                    if statusCode != 200 {
//                        Log.shared().print(page: "APIRequestor", fn: "connection.info:statusCode", type: "ERROR", text: "\(statusCode)")
//                        let errorTemp = NSError(domain:"connection.info:statusCode", code:500, userInfo:nil)
//                        return completion(nil, errorTemp )
//                    }
//                    
//                    // Get the first byte as a Data object to check if its a number for validation. first character must be 0-9
//                    if let firstByteData = data?.first.map({ Data([$0]) }) {
//                        if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
//                           
//                            let character: Character = Character(firstCharacterString)
//                            if !character.isWholeNumber {
//                                Log.shared().print(page: "APIRequestor", fn: "connection.info:statusCode", type: "ERROR", text: "NOT_WHOLE_NUMBER")
//                                let errorTemp = NSError(domain:"connection.info", code:501, userInfo:nil)
//                                return completion(nil, errorTemp )
//                            }
//                            
//                        }
//                    }
//                    
//                    if ((data?.isEmpty) == nil) {
//                        Log.shared().print(page: "APIRequestor", fn: "connection.info:statusCode", type: "ERROR", text: "DATA_EMPTY")
//                        let errorTemp = NSError(domain:"connection.info", code:502, userInfo:nil)
//                        return completion(nil, errorTemp )
//                    }
//                      
//                    completion(data, error)
//                }
//                
//                task.progress.resume()
//                
//            case .frigate:
//                
//                //SET JWT 
//                guard let jwt = try? await generateJWT() else { return }
//                
//                //Make Call
//                await connectToFrigateAPIWithJWT( host: urlString, jwtToken: jwt, endpoint: "/api/version"){ data, error in
//                      
//                    // Get the first byte as a Data object to check if its a number for validation
//                    if let firstByteData = data?.first.map({ Data([$0]) }) {
//                        if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
//                          
//                            let character: Character = Character(firstCharacterString)
//                            if !character.isWholeNumber {
//                                let errorTemp = NSError(domain:"", code:500, userInfo:nil)
//                                return completion(nil, errorTemp )
//                            }
//                        }
//                    }
//                    
//                    if ((data?.isEmpty) == nil) {
//                        let errorTemp = NSError(domain:"", code:500, userInfo:nil)
//                        return completion(nil, errorTemp )
//                    }
//                    
//                    //printData(data ?? "NO DATA FOUND".data(using: .utf8)!)
//                    return completion(data,error)
//                }
//            case .bearer:
//                
//                //SET JWT
//                guard let jwt = try? await generateJWTBearer() else { return }
//                
//                //Make Call
//                await connectWithJWT( host: urlString, jwtToken: jwt, endpoint: "/api/version"){ data, error in
//                      
//                    // Get the first byte as a Data object to check if its a number for validation
//                    if let firstByteData = data?.first.map({ Data([$0]) }) {
//                        if let firstCharacterString = String(data: firstByteData, encoding: .utf8) {
//                          
//                            let character: Character = Character(firstCharacterString)
//                            if !character.isWholeNumber {
//                                let errorTemp = NSError(domain:"", code:500, userInfo:nil)
//                                return completion(nil, errorTemp )
//                            }
//                        }
//                    }
//                    
//                    if ((data?.isEmpty) == nil) {
//                        let errorTemp = NSError(domain:"", code:500, userInfo:nil)
//                        return completion(nil, errorTemp )
//                    }
//                    
//                    //printData(data ?? "NO DATA FOUND".data(using: .utf8)!)
//                    return completion(data,error)
//                }
//            default:
//                print("Do nothing here for now")
//                print("APIRequestor: checkConnectionStatus: AuthType is -- 'not_going_to_work_on_purpose'")
//                
//                let badAddress = "255.255.255.256"
//                print("\(badAddress)/api/version/breakME") //intentionlly made this call not work
//                guard let url = URL(string: "\(urlString)/api/version") else {
//                    Log.shared().print(page: "APIRequestor", fn: "checkConnectionStatus", type: "ERROR", text: "")
//                    return
//                }
//                 
//                var request = URLRequest(url: url)
//                request.httpMethod = "GET"
//                 
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
//                let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//                     
//                    if let httpResponse = response as? HTTPURLResponse {
//                        
//                        if httpResponse.statusCode != 200 {
//                            let errorTemp = NSError(domain:"", code:httpResponse.statusCode, userInfo:nil)
//                            return completion(nil, errorTemp)
//                        }
//                    } else {
//                        var errorTemp = NSError(domain:"", code:500, userInfo:nil)
//                        return completion(nil, errorTemp )
//                    }
//                     
//                    printData(data ?? "NO DATA FOUND".data(using: .utf8)!)
//                    completion(data, error)
//                }
//                 
//                task.progress.resume()
//            }
//            
//        }
//    }
//}
//
//extension APIRequester: URLSessionDelegate {
//    
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        
//        // trust the HTTPS server
//        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
//    }
//    
//    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//        // We've got an error
//        if let err = error {
//            print("Error APIRequestor urlSession: \(err.localizedDescription)")
//            Log.shared().print(page: "APIRequestor", fn: "urlSession", type: "ERROR", text: "\(err.localizedDescription)")
//        }
//    }
//}
//
//struct FrigateResponse: Codable {
//    
//    let message: String?
//    let success: Bool?
//}
