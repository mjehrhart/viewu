//
//  Auth.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/1/25.
//

import Foundation
import JWTKit
import SwiftUI

struct JWTPL: JWTPayload {
    var sub: SubjectClaim
    var exp: ExpirationClaim
    var role: String
    
    func verify(using key: some JWTAlgorithm) throws {
        try self.exp.verifyNotExpired()
    }
}

//class FrigateURLSessionDelegate: NSObject, URLSessionDelegate {
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        
//        // Allow the connection by trusting the self-signed certificate
//        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
//            completionHandler(.useCredential, credential)
//        } else {
//            completionHandler(.performDefaultHandling, nil)
//        }
//        
//    }
//}
class FrigateURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host
        let method = challenge.protectionSpace.authenticationMethod

        Log.debug(
            page: "Auth",
            fn: "FrigateURLSessionDelegate.urlSession(didReceive:challenge:)",
            "Received auth challenge for host=\(host), method=\(method)"
        )

        // For Frigate LAN / self-signed certs we intentionally trust serverTrust.
        if method == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

 
let frigateDelegate = FrigateURLSessionDelegate()
 
/*
func connectToFrigateAPIWithJWT(
    host: String,
    jwtToken: String,
    endpoint: String,
    completion: @escaping (Data?, Error?) -> Void
) async {

    let urlString = "\(host)\(endpoint)"

    guard let url = URL(string: urlString) else {
        let error = NSError(
            domain: "InvalidURL",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"]
        )
        Log.error(page: "Auth",
                           fn: "connectToFrigateAPIWithJWT", error.localizedDescription)
        return completion(nil, error)
    }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "GET"

    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: frigateDelegate, delegateQueue: nil)

    let task = session.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {

            if let error = error {
                Log.error(
                    page: "Auth",
                    fn: "connectToFrigateAPIWithJWT", "Network error: \(error.localizedDescription)"
                )
                return completion(nil, error)
            }

            guard let data = data else {
                let noDataError = NSError(
                    domain: "NoData",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No data returned from API: \(urlString)"]
                )
                Log.error(
                    page: "Auth",
                    fn: "connectToFrigateAPIWithJWT", noDataError.localizedDescription
                )
                return completion(nil, noDataError)
            }

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                let apiError = NSError(
                    domain: "APIError",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode) for \(urlString)"]
                )
                Log.error(
                    page: "Auth",
                    fn: "connectToFrigateAPIWithJWT", apiError.localizedDescription
                )
                return completion(nil, apiError)
            }

            Log.debug(
                page: "Auth",
                fn: "connectToFrigateAPIWithJWT", "Request succeeded. url=\(urlString), bytes=\(data.count)"
            )

            completion(data, nil)
        }
    }

    Log.debug(
        page: "Auth",
        fn: "connectToFrigateAPIWithJWT", "Starting request. url=\(urlString)"
    )

    task.resume()
}
*/

func connectToFrigateAPIWithJWT(
    host: String,
    jwtToken: String,
    endpoint: String,
    completion: @escaping (Data?, Error?) -> Void
) async {

    // Normalize host + endpoint similar to Cloudflare helper
    let trimmedHost = host.hasSuffix("/") ? String(host.dropLast()) : host

    let normalizedEndpoint: String
    if endpoint.isEmpty {
        normalizedEndpoint = ""
    } else if endpoint.hasPrefix("/") {
        normalizedEndpoint = endpoint
    } else {
        normalizedEndpoint = "/" + endpoint
    }

    let urlString = trimmedHost + normalizedEndpoint

    Log.debug(
        page: "Auth",
        fn: "connectToFrigateAPIWithJWT",
        "Starting request. host=\(host), endpoint=\(endpoint), urlString=\(urlString)"
    )

    guard let url = URL(string: urlString) else {
        let error = NSError(
            domain: "InvalidURL",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"]
        )
        Log.error(
            page: "Auth",
            fn: "connectToFrigateAPIWithJWT",
            error.localizedDescription
        )
        return completion(nil, error)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

    let configuration = URLSessionConfiguration.default
    let session = URLSession(
        configuration: configuration,
        delegate: frigateDelegate,
        delegateQueue: nil
    )

    let task = session.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {

            // 1. Transport / network error
            if let error = error {
                Log.error(
                    page: "Auth",
                    fn: "connectToFrigateAPIWithJWT",
                    "Network error: \(error.localizedDescription)"
                )
                return completion(nil, error)
            }

            // 2. Ensure data exists
            guard let data = data else {
                let noDataError = NSError(
                    domain: "NoData",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No data returned from API: \(urlString)"]
                )
                Log.error(
                    page: "Auth",
                    fn: "connectToFrigateAPIWithJWT",
                    noDataError.localizedDescription
                )
                return completion(nil, noDataError)
            }

            // 3. HTTP status validation
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    let apiError = NSError(
                        domain: "APIError",
                        code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "API request failed with status \(httpResponse.statusCode) for \(urlString)"
                        ]
                    )

                    Log.error(
                        page: "Auth",
                        fn: "connectToFrigateAPIWithJWT",
                        apiError.localizedDescription
                    )
                    return completion(nil, apiError)
                } else {
                    Log.debug(
                        page: "Auth",
                        fn: "connectToFrigateAPIWithJWT",
                        "Request succeeded. status=\(httpResponse.statusCode), url=\(urlString), bytes=\(data.count)"
                    )
                }
            } else {
                Log.debug(
                    page: "Auth",
                    fn: "connectToFrigateAPIWithJWT",
                    "Response was not an HTTPURLResponse. url=\(urlString), bytes=\(data.count)"
                )
            }

            // 4. Success
            completion(data, nil)
        }
    }

    task.resume()
}




func generateJWTFrigate() async throws -> String {
    
    @AppStorage("frigateUserRole") var frigateUserRole: String = "admin"
    @AppStorage("frigateUser") var frigateUser: String = "admin"
    @AppStorage("frigateBearerSecret") var bearerSecret: String = ""
    
    // Create an instance of custom payload
    let payload = JWTPL(
        sub: SubjectClaim(value: frigateUser),
        exp: .init(value: .distantFuture), //ExpirationClaim(value: Date().addingTimeInterval(3600)),
        role: frigateUserRole
    )
      
    let keys = JWTKeyCollection()
    let secretData = Data(bearerSecret.utf8)
    
    let secret: HMACKey = HMACKey(from: secretData)
    await keys.add(hmac: secret, digestAlgorithm: .sha256)
    let jwtToken = try await keys.sign(payload)
      
    return jwtToken
}

func generateSyncJWTFrigate() throws -> String {
    
    var result: Result<String, Error>?
    let semaphore = DispatchSemaphore(value: 0)

    Task {
        do {
            let token = try await generateJWTFrigate() 
            result = .success(token)
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }

    semaphore.wait()

    return try result!.get()
}
