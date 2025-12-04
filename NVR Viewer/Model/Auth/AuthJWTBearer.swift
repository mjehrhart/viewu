//
//  AuthJWTBearer.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 12/3/25.
//

import Foundation
import JWTKit
import SwiftUI


class JWTBearerURLSessionDelegate: NSObject, URLSessionDelegate {
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
 
let jwtBearerDelegate = JWTBearerURLSessionDelegate()
 
func connectWithJWT( host: String, jwtToken: String, endpoint: String, completion: @escaping (Data?, Error?) -> Void) async {
    
    let urlString = "\(host)\(endpoint)" 
          
    guard let url = URL(string: urlString) else {
        // call the completion handler instead of using 'throw'
        let error = NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        return completion(nil, error)
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
    //request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set Content-Type for JSON body if applicable
    request.httpMethod = "GET"
    
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: jwtBearerDelegate, delegateQueue: nil)
    
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
 
func generateJWTBearer() async throws -> String {
    
    @AppStorage("bearerSecret") var bearerSecret: String = ""
    
    // Create an instance of custom payload
    let payload = JWTPL(
        sub: SubjectClaim(value: "admin"),
        exp: .init(value: .distantFuture), //ExpirationClaim(value: Date().addingTimeInterval(3600)),
        role: "admin"
    )
      
    let keys = JWTKeyCollection()
    let secretData = Data(bearerSecret.utf8)
    
    let secret: HMACKey = HMACKey(from: secretData)
    await keys.add(hmac: secret, digestAlgorithm: .sha256)
    let jwtToken = try await keys.sign(payload)
     
    return jwtToken
}
