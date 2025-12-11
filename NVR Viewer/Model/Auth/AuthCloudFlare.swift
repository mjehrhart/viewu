//
//  AuthCloudFlare.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/10/25.
//

import Foundation
import SwiftUI

/// URLSessionDelegate for Cloudflare Access requests.
/// We *do not* bypass TLS here since Cloudflare uses valid certificates.
class CloudflareAccessURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        let host = challenge.protectionSpace.host
        let method = challenge.protectionSpace.authenticationMethod

        Log.shared().print(
            page: "AuthCloudFlare",
            fn: "urlSession(didReceive:challenge:)",
            type: "INFO",
            text: "Received auth challenge for host=\(host), method=\(method). Using default TLS handling."
        )

        // Use the system’s normal certificate validation
        completionHandler(.performDefaultHandling, nil)
    }
}

let cloudflareAccessDelegate = CloudflareAccessURLSessionDelegate()
let defaults = UserDefaults.standard
let clientId = defaults.string(forKey: "cloudFlareClientId") ?? ""
let clientSecret = defaults.string(forKey: "cloudFlareSecret") ?? ""

/**
 Connect to a resource protected by Cloudflare Access using a Service Token.

 - Parameters:
   - host: Base URL including scheme, e.g. "https://frigate.view-u.com"
   - endpoint: Path, e.g. "/api/events"
   - completion: Called on the main queue with `Data` or `Error`
 */
func connectWithCloudflareAccess(
    host: String,
    endpoint: String,
    completion: @escaping (Data?, Error?) -> Void
) async {
    Log.shared().print(
        page: "AuthCloudFlare",
        fn: "connectWithCloudflareAccess",
        type: "INFO",
        text: "Starting Cloudflare request. host=\(host), endpoint=\(endpoint)"
    )

    // Normalize host + endpoint to avoid double slashes or missing slash.
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

    Log.shared().print(
        page: "AuthCloudFlare",
        fn: "connectWithCloudflareAccess",
        type: "INFO",
        text: "Normalized URL components. trimmedHost=\(trimmedHost), normalizedEndpoint=\(normalizedEndpoint), urlString=\(urlString)"
    )

    guard let url = URL(string: urlString) else {
        let errorMessage = "Invalid URL: \(urlString)"
        Log.shared().print(
            page: "AuthCloudFlare",
            fn: "connectWithCloudflareAccess",
            type: "ERROR",
            text: errorMessage
        )

        let error = NSError(
            domain: "InvalidURL",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        completion(nil, error)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    // Cloudflare Access service token headers
    request.setValue(clientId, forHTTPHeaderField: "CF-Access-Client-Id")
    request.setValue(clientSecret, forHTTPHeaderField: "CF-Access-Client-Secret")

    Log.shared().print(
        page: "AuthCloudFlare",
        fn: "connectWithCloudflareAccess",
        type: "INFO",
        text: """
        Prepared request:
          URL=\(url.absoluteString)
          Method=GET
          CF-Access-Client-Id present=\(!clientId.isEmpty)
          CF-Access-Client-Secret present=\(!clientSecret.isEmpty)
        """
    )

    let configuration = URLSessionConfiguration.default
    let session = URLSession(
        configuration: configuration,
        delegate: cloudflareAccessDelegate,
        delegateQueue: nil
    )

    Log.shared().print(
        page: "AuthCloudFlare",
        fn: "connectWithCloudflareAccess",
        type: "INFO",
        text: "Created URLSession with CloudflareAccessURLSessionDelegate. Starting dataTask."
    )

    let task = session.dataTask(with: request) { data, response, error in
        // You’re already hopping back to the main queue
        DispatchQueue.main.async {
            // 1. Network / transport error
            if let error = error {
                Log.shared().print(
                    page: "AuthCloudFlare",
                    fn: "connectWithCloudflareAccess.dataTask",
                    type: "ERROR",
                    text: "Network/transport error: \(error.localizedDescription)"
                )
                completion(nil, error)
                return
            }

            // 2. Ensure we actually got data
            guard let data = data else {
                let message = "No data returned from API"
                Log.shared().print(
                    page: "AuthCloudFlare",
                    fn: "connectWithCloudflareAccess.dataTask",
                    type: "ERROR",
                    text: message
                )
                let noDataError = NSError(
                    domain: "NoData",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
                completion(nil, noDataError)
                return
            }

            // 3. HTTP status validation
            if let httpResponse = response as? HTTPURLResponse {
                Log.shared().print(
                    page: "AuthCloudFlare",
                    fn: "connectWithCloudflareAccess.dataTask",
                    type: "INFO",
                    text: "Received HTTP response. statusCode=\(httpResponse.statusCode), url=\(httpResponse.url?.absoluteString ?? "nil")"
                )

                if httpResponse.statusCode != 200 {
                    let message = "API request failed with status \(httpResponse.statusCode)"
                    Log.shared().print(
                        page: "AuthCloudFlare",
                        fn: "connectWithCloudflareAccess.dataTask",
                        type: "ERROR",
                        text: message
                    )
                    let apiError = NSError(
                        domain: "APIError",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )
                    completion(nil, apiError)
                    return
                }
            } else {
                Log.shared().print(
                    page: "AuthCloudFlare",
                    fn: "connectWithCloudflareAccess.dataTask",
                    type: "INFO",
                    text: "Response was not an HTTPURLResponse."
                )
            }

            // 4. Success
            Log.shared().print(
                page: "AuthCloudFlare",
                fn: "connectWithCloudflareAccess.dataTask",
                type: "INFO",
                text: "Cloudflare Access request succeeded. Data length=\(data.count) bytes."
            )
            completion(data, nil)
        }
    }

    task.resume()
    Log.shared().print(
        page: "AuthCloudFlare",
        fn: "connectWithCloudflareAccess",
        type: "INFO",
        text: "dataTask.resume() called for URL=\(url.absoluteString)"
    )
}
