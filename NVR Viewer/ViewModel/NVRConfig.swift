//
//  NVRConfig.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/3/24.
//

import Foundation
import SwiftUI
 
final class NVRConfig: ObservableObject  {
    
    var https = false
    var url = "0.0.0.1"
    var port = "5000"
    
    let api = APIRequester()
    static let _shared = NVRConfig() 
    
    @AppStorage("nvrIsHttps") var httpsNVR: Bool = true
    @AppStorage("nvrIPAddress") var urlNVR: String = "0.0.0.0"
    @AppStorage("nvrPortAddress") var portNVR: String = "5000"
      
    @AppStorage("frigateIsHttps") var httpsFrigate: Bool = true
    @AppStorage("frigateIPAddress") var urlFrigate: String = "0.0.0.0"
    @AppStorage("frigatePortAddress") var portFrigate: String = "8971"
    
    @AppStorage("bearerIsHttps") var httpsJWTBearer: Bool = true
    @AppStorage("bearerIPAddress") var urlJWTBearer: String = "0.0.0.0"
    @AppStorage("bearerPortAddress") var portJWTBearer: String = "5000"
     
    @AppStorage("authType") private var authType: AuthType = .none
    @Published var tmpAuthType: AuthType = .none {
        didSet {
            authType = tmpAuthType // Update AppStorage when authType changes
        }
    }
 
    @Published var connectionState: NVRConnectionState = .disconnected {
        willSet {
            objectWillChange.send()
        }
    }
    
    class func shared() -> NVRConfig {
        return _shared
    }
    
    init() {
        self.tmpAuthType = authType
        self.url = self.getInitIP()
        //self.https = self.getInitHttps()
        self.port = getInitPort()
    }
    private func getInitIP() -> String {
        switch authType{
        case .none:
            return  urlNVR
        case .bearer:
            return urlJWTBearer
        case .frigate:
            return urlFrigate
        case .cloudflare:
            return ""
        case .custom:
            return ""
        }
    }
    private func getInitPort() -> String {
        switch authType{
        case .none:
            return  portNVR
        case .bearer:
            return portJWTBearer
        case .frigate:
            return portFrigate
        case .cloudflare:
            return ""
        case .custom:
            return ""
        }
    }
    
    private func getInitHttps() -> Bool {
        switch authType{
        case .none:
            if httpsNVR {
                return true
            } else {
                return false
            }
        case .bearer:
            if httpsJWTBearer {
                return true
            } else {
                return false
            }
        case .frigate:
            if httpsFrigate {
                return true
            } else {
                return false
            }
        case .cloudflare:
            // do nothing
            return true
        case .custom:
            // do nothing
            return true
        }
    }
    
    func getAuthType() -> AuthType{
        return authType
    }
    
    func setAuthType(authType: AuthType) {
        self.authType = authType
    }
    
    func setHttps(http:Bool) {
         
        switch authType{
        case .none:
            self.https = httpsNVR
        case .bearer:
            self.https = httpsJWTBearer
        case .frigate:
            self.https = httpsFrigate
        case .cloudflare:
            break
            // do nothing
        case .custom:
            break
            // do nothing
        }
        //self.https = http
    }
     
    func setIP(ip:String) {
        switch authType{
        case .none:
            self.url = ip
        case .bearer:
            self.url = urlJWTBearer
        case .frigate:
            self.url = urlFrigate
        case .cloudflare:
            break
            // do nothing
        case .custom:
            break
            // do nothing
        }
        //self.url = ip
    }
    
    func setPort(ports:String) { 
        
        switch authType{
        case .none:
            self.port = portNVR
        case .bearer:
            self.port = portJWTBearer
        case .frigate:
            self.port = portFrigate
        case .cloudflare:
            break
        case .custom:
            break
        }
        //self.port = port
    }
    
    func getIP() -> String {
        return url
    }
    
    func getUrl() -> String {
        
        var http: String {
             
            switch authType{
            case .none:
                if httpsNVR {
                    return "https://"
                } else {
                    return "http://"
                }
            case .bearer:
                if httpsJWTBearer {
                    return "https://"
                } else {
                    return "http://"
                }
            case .frigate:
                if httpsFrigate {
                    return "https://"
                } else {
                    return "http://"
                }
            case .cloudflare:
                // do nothing
                return ""
            case .custom:
                // do nothing
                return ""
            }
        }
        
        let url: String = http + self.url + ":" + self.port
        //print("getUrl = \(url)")
        return url
    }
    
    func getConnectionState() -> Bool {
        
        var isConnected: Bool {
            switch self.connectionState {
            case .connected:
                return true
            case .disconnected:
                return false
            }
        }
        return isConnected
    }
}
