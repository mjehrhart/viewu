//
//  WSSProbeDelegate.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/13/25.
//

import Foundation

private final class WSSProbeDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let http = task.response as? HTTPURLResponse {
            print("[wssProbe] completed status=\(http.statusCode) headers=\(http.allHeaderFields)")
        } else {
            print("[wssProbe] completed no HTTPURLResponse; error=\(String(describing: error))")
        }
    }
}

struct CloudflareAccessCredentials {
    let clientId: String
    let clientSecret: String
}

func runWSSProbe(url: URL, cloudflareCreds: CloudflareAccessCredentials) {
    var cfg = URLSessionConfiguration.ephemeral
    cfg.httpAdditionalHeaders = [
        "CF-Access-Client-Id": cloudflareCreds.clientId,
        "CF-Access-Client-Secret": cloudflareCreds.clientSecret
    ]

    let session = URLSession(configuration: cfg,
                             delegate: WSSProbeDelegate(),
                             delegateQueue: nil)

    // IMPORTANT: This is the “mqtt” subprotocol, without relying on manual Sec-WebSocket-Protocol headers.
    let task = session.webSocketTask(with: url, protocols: ["mqtt"])
    task.resume()

    task.sendPing { err in
        if let err = err {
            print("[wssProbe] ping failed: \(err)")
        } else {
            print("[wssProbe] ping ok")
        }
    }
}
