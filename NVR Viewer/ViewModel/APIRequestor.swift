//
//  APIRequestor.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/13/24.
//

import Foundation

struct FrigateResponse: Codable {
    
    let message: String?
    let success: Bool?
}

class APIRequester: NSObject {
    
    func fetchNVRConfig(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
//            do {
//                let results = try JSONDecoder().decode(NVRConfigurationCall.self, from: data!)
//                print("results=", results)
//            }catch{
//                print("Error Message goes here - 1001")
//            }
            
            
            
            completion(data, error)
        }
        task.progress.resume()
    }
    
    func fetchImage(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            //print("APIRequester::fetchImage()------------------------------------------>")
            
            
            //FOR DEBUGGING
            //TODO add ! to data below
            guard let data = data else { return }
            
            if(data.count < 50){
                do {
                    let de = try JSONDecoder().decode(FrigateResponse.self, from: data)
                    //                    print("de=", de)
                    //                    print(de.message)
                    //                    print(de.success)
                    if de.success! == false {
                        var errorTemp = NSError(domain:"com.john.matthew", code: 101,  userInfo:nil)
                        completion(nil, errorTemp)
                        return
                    }
                }catch{
                    print("Error Message goes here - 1001")
                }
            }
            
            
            completion(data, error)
        }
        task.progress.resume()
    }
    
    func checkConnectionStatus(urlString: String, completion: @escaping (Data?, Error?) -> Void){
        
        guard let url = URL(string: "\(urlString)/api/version") else {
            print("checkConnectionStatus::------ERROR-----::")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        //request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            //            print("---------------------->DATA")
            //            print(data)
            //
            //            print("---------------------->ERROR")
            //            print(error)
            
            completion(data, error)
        }
        
        task.progress.resume()
    }
}

extension APIRequester: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // trust the HTTPS server
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        // We've got an error
        if let err = error {
            print("Error: \(err.localizedDescription)")
        }
    }
}

//    private func fetchURLImage(){
//
//        print("INSIDE fetchURLImage::VIEWUiImageFull")
//        //guard let url = URL(string: "http://127.0.0.1:5555/api/events/1708968097.297187-7pf02z/snapshot.jpg?bbox=1") else {return}
//        guard let url = URL(string: self.urlString) else {return}
//
//        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, res, error in
//            self.data = data
//        })
//
//        task.progress.resume()
//    }
