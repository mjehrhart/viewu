//
//  AuthJWTBearer.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/3/25.
//

import Foundation
import JWTKit
import SwiftUI

final class JWTBearerURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

private let jwtBearerDelegate = JWTBearerURLSessionDelegate()

func connectWithJWT(
    host: String,
    jwtToken: String,
    endpoint: String,
    completion: @escaping (Data?, Error?) -> Void
) async {

    let urlString = "\(host)\(endpoint)"

    guard let url = URL(string: urlString) else {
        let err = NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        completion(nil, err)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(normalizedBearer(jwtToken), forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: jwtBearerDelegate, delegateQueue: nil)

    session.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {

            if let error = error {
                completion(nil, error)
                return
            }

            guard let data = data else {
                let noDataError = NSError(domain: "NoData", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data returned from API"])
                completion(nil, noDataError)
                return
            }

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let apiError = NSError(domain: "APIError", code: http.statusCode,
                                       userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(http.statusCode)"])
                completion(nil, apiError)
                return
            }

            completion(data, nil)
        }
    }.resume()
}

func generateJWTBearer() async throws -> String {

    let defaults = UserDefaults.standard
    let bearerSecret = defaults.string(forKey: "bearerSecret") ?? ""

    let payload = JWTPL(
        sub: SubjectClaim(value: "admin"),
        exp: .init(value: .distantFuture),
        role: "admin"
    )

    let keys = JWTKeyCollection()
    let secretData = Data(bearerSecret.utf8)
    let secret: HMACKey = HMACKey(from: secretData)
    await keys.add(hmac: secret, digestAlgorithm: .sha256)

    let jwtToken = try await keys.sign(payload)

    // Cache for extension use
    defaults.set(jwtToken, forKey: "jwtBearer")

    // Keep App Group in sync for NotificationService
    NotificationAuthShared.syncFromStandardDefaults()

    return jwtToken
}

func generateSyncJWTBearer() throws -> String {
    var result: Result<String, Error>?
    let semaphore = DispatchSemaphore(value: 0)

    Task {
        do { result = .success(try await generateJWTBearer()) }
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

