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
    
    //let nvr = NVRConfig.shared()
    //@AppStorage("background_fetch_events_epochtime") private var backgroundFetchEventsEpochtime: String = "0"
    //UserDefaults.standard.set("@twostraws", forKey: "background_fetch_events_epochtime")
    
    func postImageToFrigatePlus(urlString: String, eventId: String, completion: @escaping (Data?, Error?) -> Void) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
             
            guard let data = data else { return }
             
            completion(data, error)
        }
        task.progress.resume()
    }
   
    func fetchEventsInBackground(urlString: String, backgroundFetchEventsEpochtime: String, epsType: String){
        
        //DEV
        //Load Events
        //let urlEvents = nvr.getUrl()
        let urlStringEvents = urlString + "/api/events?limit=10000&after=\(backgroundFetchEventsEpochtime)"
        print("===== fetchEventsInBackground::url")
        print(urlStringEvents)
        
        let after = Int(Date().timeIntervalSince1970)
        //backgroundFetchEventsEpochtime = String(after)
        UserDefaults.standard.set(String(after), forKey: "background_fetch_events_epochtime")
        
        fetchNVREvents(urlString: urlStringEvents) { data, error in
            
            guard let data = data else { return }
             
            do{
                let arrayEvents = try JSONDecoder().decode([NVRConfigurationHTTP].self, from: data)
                
                for event in arrayEvents {
                     
                    let url = urlString //self.nvr.getUrl()
                    let id = event.id
                    let frameTime = event.start_time
                    
                    var enteredZones = ""
                    for zone in event.zones! {
                        enteredZones += zone + "|"
                    }
                      
                    var eps = EndpointOptions()
                    eps.snapshot = url + "/api/events/\(id)/snapshot.jpg?bbox=1"
                    eps.cameraName = event.camera
                    eps.m3u8 = url + "/vod/event/\(id)/master.m3u8"
                    eps.frameTime = event.start_time
                    eps.label = event.label
                    eps.id = event.id
                    eps.thumbnail = url + "/api/events/\(id)/thumbnail.jpg"
                    eps.camera = url + "/cameras/\(event.camera)"
                    eps.debug = url + "/api/\(event.camera)?h=480"
                    eps.image = url + "/api/\(event.camera)/recordings/\(frameTime)/snapshot.png"
                    eps.score = 0.0
                    eps.transportType = "viewu"
                    eps.type = epsType
                    eps.currentZones = ""
                    eps.enteredZones = enteredZones
                    eps.sublabel = event.sub_label
                     
                    //Check if value is nil
                    if eps.sublabel == nil {
                        eps.sublabel = ""
                    }
                    if eps.currentZones == nil {
                        eps.currentZones = ""
                    }
                    if eps.enteredZones == nil {
                        eps.enteredZones = ""
                    }
                    
                    let _ = EventStorage.shared.insertOrUpdate(
                          id: eps.id!,
                          frameTime: eps.frameTime!,
                          score: eps.score!,
                          type: eps.type!,
                          cameraName: eps.cameraName!,
                          label: eps.label!,
                          thumbnail: eps.thumbnail!,
                          snapshot: eps.snapshot!,
                          m3u8: eps.m3u8!,
                          camera: eps.camera!,
                          debug: eps.debug!,
                          image: eps.image!,
                          transportType: eps.transportType!,
                          subLabel: eps.sublabel!, //ADDED 5/26 ?? "" TODO !
                          currentZones: eps.currentZones!,
                          enteredZones: eps.enteredZones!
                    )
                    
                }
            } catch(let err) {
                print("Error Message goes here - 1002")
                print(err)
                Log.shared().print(page: "APIRequestor", fn: "fetchEventsInBackground", type: "ERROR", text: "\(err)")
            }
            
            
        }
    }
    
    
    func fetchNVREvents(urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
 
            completion(data, error)
        }
        task.progress.resume()
    }
    
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
            Log.shared().print(page: "APIRequestor", fn: "checkConnectionStatus", type: "ERROR", text: "")
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
            Log.shared().print(page: "APIRequestor", fn: "urlSession", type: "ERROR", text: "\(err.localizedDescription)")
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
