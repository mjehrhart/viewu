//
//  DefaultChallengeURLSessionDelegate..swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/13/25.
//

import Foundation

/// Use this for Cloudflare (public CA) traffic.
/// It always completes the challenge, which removes the API MISUSE and prevents “hanging” handshakes.
final class DefaultChallengeURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // For Cloudflare’s publicly trusted certs, do default handling.
        completionHandler(.performDefaultHandling, nil)
    }
}
