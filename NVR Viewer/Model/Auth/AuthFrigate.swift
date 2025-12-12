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

final class FrigateURLSessionDelegate: NSObject, URLSessionDelegate {
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

        // For Frigate LAN/self-signed certs we intentionally trust serverTrust.
        if method == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

private let frigateDelegate = FrigateURLSessionDelegate()

func connectToFrigateAPIWithJWT(
    host: String,
    jwtToken: String,
    endpoint: String,
    completion: @escaping (Data?, Error?) -> Void
) async {

    let trimmedHost = host.hasSuffix("/") ? String(host.dropLast()) : host
    let normalizedEndpoint: String
    if endpoint.isEmpty { normalizedEndpoint = "" }
    else if endpoint.hasPrefix("/") { normalizedEndpoint = endpoint }
    else { normalizedEndpoint = "/" + endpoint }

    let urlString = trimmedHost + normalizedEndpoint

    Log.debug(
        page: "Auth",
        fn: "connectToFrigateAPIWithJWT",
        "Starting request. urlString=\(urlString)"
    )

    guard let url = URL(string: urlString) else {
        let error = NSError(domain: "InvalidURL", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        Log.error(page: "Auth", fn: "connectToFrigateAPIWithJWT", error.localizedDescription)
        completion(nil, error)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(normalizedBearer(jwtToken), forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: frigateDelegate, delegateQueue: nil)

    session.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {

            if let error = error {
                Log.error(page: "Auth", fn: "connectToFrigateAPIWithJWT", "Network error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }

            guard let data = data else {
                let noDataError = NSError(domain: "NoData", code: 1,
                                          userInfo: [NSLocalizedDescriptionKey: "No data returned from API: \(urlString)"])
                Log.error(page: "Auth", fn: "connectToFrigateAPIWithJWT", noDataError.localizedDescription)
                completion(nil, noDataError)
                return
            }

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let apiError = NSError(domain: "APIError", code: http.statusCode,
                                       userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(http.statusCode) for \(urlString)"])
                Log.error(page: "Auth", fn: "connectToFrigateAPIWithJWT", apiError.localizedDescription)
                completion(nil, apiError)
                return
            }

            Log.debug(page: "Auth", fn: "connectToFrigateAPIWithJWT", "Request OK. bytes=\(data.count)")
            completion(data, nil)
        }
    }.resume()
}

func generateJWTFrigate() async throws -> String {

    let defaults = UserDefaults.standard

    let frigateUserRole = defaults.string(forKey: "frigateUserRole") ?? "admin"
    let frigateUser     = defaults.string(forKey: "frigateUser") ?? "admin"
    let bearerSecret    = defaults.string(forKey: "frigateBearerSecret") ?? ""

    let payload = JWTPL(
        sub: SubjectClaim(value: frigateUser),
        exp: .init(value: .distantFuture),
        role: frigateUserRole
    )

    let keys = JWTKeyCollection()
    let secretData = Data(bearerSecret.utf8)
    let secret: HMACKey = HMACKey(from: secretData)
    await keys.add(hmac: secret, digestAlgorithm: .sha256)

    let jwtToken = try await keys.sign(payload)

    // Cache for extension use
    defaults.set(jwtToken, forKey: "jwtFrigate")

    // Keep App Group in sync for NotificationService
    NotificationAuthShared.syncFromStandardDefaults()

    return jwtToken
}

func generateSyncJWTFrigate() throws -> String {
    var result: Result<String, Error>?
    let semaphore = DispatchSemaphore(value: 0)

    Task {
        do { result = .success(try await generateJWTFrigate()) }
        catch { result = .failure(error) }
        semaphore.signal()
    }

    semaphore.wait()
    return try result!.get()
}

private func normalizedBearer(_ token: String) -> String {
    let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.lowercased().hasPrefix("bearer ") { return t }
    return "Bearer \(t)"
}
