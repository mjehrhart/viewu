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

class FrigateURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Allow the connection by trusting the self-signed certificate
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
        
    }
}
 
let frigateDelegate = FrigateURLSessionDelegate()
 
func connectToFrigateAPIWithJWT( host: String, jwtToken: String, endpoint: String, completion: @escaping (Data?, Error?) -> Void) async {
    
    
    let urlString = "\(host)\(endpoint)" 
          
    guard let url = URL(string: urlString) else {
        // call the completion handler instead of using 'throw'
        let error = NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        return completion(nil, error)
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "GET"
    
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: frigateDelegate, delegateQueue: nil)
    
    // The closure handles all potential errors that the task produces
    let task = session.dataTask(with: request) { data, response, error in
        
        DispatchQueue.main.async {
            
            // 1. If error is present, we handle it internally and return via completion
            if let error = error {
                return completion(nil, error)
                //return // Stop execution here
            }
            
            // 2. Ensure data exists
            guard let data = data else {
                let noDataError = NSError(domain: "NoData", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data returned from API"])
                return completion(nil, error)
                //return
            }
            
            // 3. Handle HTTP status code errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let apiError = NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
                return completion(nil, error)
                //return
            }
            
            // 4. Success: Call the completion handler with the Data
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
