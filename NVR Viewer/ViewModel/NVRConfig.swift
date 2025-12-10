//
//  NVRConfig.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/3/24.
//

import Foundation
import Combine

final class NVRConfig: ObservableObject {

    // MARK: - Singleton

    static let _shared = NVRConfig()
    //static var shared: NVRConfig { _shared }

    class func shared() -> NVRConfig {
        return _shared
    }

    // MARK: - Storage keys

    private enum Keys {
        static let nvrIsHttps        = "nvrIsHttps"
        static let nvrIPAddress      = "nvrIPAddress"
        static let nvrPortAddress    = "nvrPortAddress"

        static let frigateIsHttps    = "frigateIsHttps"
        static let frigateIPAddress  = "frigateIPAddress"
        static let frigatePortAddress = "frigatePortAddress"

        static let bearerIsHttps     = "bearerIsHttps"
        static let bearerIPAddress   = "bearerIPAddress"
        static let bearerPortAddress = "bearerPortAddress"

        static let authType          = "authType"
    }

    private let defaults = UserDefaults.standard

    let api = APIRequester()

    // MARK: - Active connection values (for current authType)

    @Published var https: Bool = false
    @Published var url: String = "0.0.0.1"
    @Published var port: String = "5000"

    // Currently selected auth type (for UI and behavior)
    @Published var tmpAuthType: AuthType = .none {
        didSet {
            storedAuthType = tmpAuthType
            loadProfile(for: tmpAuthType)
        }
    }

    // Connection state for UI
    @Published var connectionState: NVRConnectionState = .disconnected

    // MARK: - Init

    init() {
        // Load auth type from storage, then load that profile
        let initialType = storedAuthType
        tmpAuthType = initialType      // triggers loadProfile(for:)
    }

    // MARK: - Stored per-profile values

    /// The persisted "real" authType in UserDefaults.
    private var storedAuthType: AuthType {
        get {
            if let raw = defaults.string(forKey: Keys.authType),
               let value = AuthType(rawValue: raw) {
                return value
            }
            return .none
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.authType)
        }
    }

    private func storedProfile(for type: AuthType) -> (https: Bool, url: String, port: String) {
        switch type {
        case .none:
            let https = defaults.object(forKey: Keys.nvrIsHttps) as? Bool ?? true
            let url   = defaults.string(forKey: Keys.nvrIPAddress) ?? "0.0.0.0"
            let port  = defaults.string(forKey: Keys.nvrPortAddress) ?? "5000"
            return (https, url, port)

        case .frigate:
            let https = defaults.object(forKey: Keys.frigateIsHttps) as? Bool ?? true
            let url   = defaults.string(forKey: Keys.frigateIPAddress) ?? "0.0.0.0"
            let port  = defaults.string(forKey: Keys.frigatePortAddress) ?? "8971"
            return (https, url, port)

        case .bearer:
            let https = defaults.object(forKey: Keys.bearerIsHttps) as? Bool ?? true
            let url   = defaults.string(forKey: Keys.bearerIPAddress) ?? "0.0.0.0"
            let port  = defaults.string(forKey: Keys.bearerPortAddress) ?? "5000"
            return (https, url, port)

        case .cloudflare, .custom:
            // Not yet implemented; keep these blank until you add specific behavior.
            return (true, "", "")
        }
    }

    private func saveProfile(for type: AuthType, https: Bool, url: String, port: String) {
        switch type {
        case .none:
            defaults.set(https, forKey: Keys.nvrIsHttps)
            defaults.set(url,   forKey: Keys.nvrIPAddress)
            defaults.set(port,  forKey: Keys.nvrPortAddress)

        case .frigate:
            defaults.set(https, forKey: Keys.frigateIsHttps)
            defaults.set(url,   forKey: Keys.frigateIPAddress)
            defaults.set(port,  forKey: Keys.frigatePortAddress)

        case .bearer:
            defaults.set(https, forKey: Keys.bearerIsHttps)
            defaults.set(url,   forKey: Keys.bearerIPAddress)
            defaults.set(port,  forKey: Keys.bearerPortAddress)

        case .cloudflare, .custom:
            // No-op for now
            break
        }
    }

    private func loadProfile(for type: AuthType) {
        let profile = storedProfile(for: type)
        https = profile.https
        url   = profile.url
        port  = profile.port
    }

    // MARK: - Public API (compatible with existing code)

    func getAuthType() -> AuthType {
        tmpAuthType
    }

    func setAuthType(authType: AuthType) {
        tmpAuthType = authType       // this will persist and reload profile
    }

    func setHttps(http: Bool) {
        https = http
        saveProfile(for: tmpAuthType, https: https, url: url, port: port)
    }

    func setIP(ip: String) {
        url = ip
        saveProfile(for: tmpAuthType, https: https, url: url, port: port)
    }

    func setPort(ports: String) {
        port = ports
        saveProfile(for: tmpAuthType, https: https, url: url, port: port)
    }

    func getIP() -> String {
        url
    }

    func getUrl() -> String {
        let scheme = https ? "https://" : "http://"
        return "\(scheme)\(url):\(port)"
    }

    func getConnectionState() -> Bool {
        connectionState == .connected
    }
}

// MARK: - Remove
////
////  NVRConfig.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 3/3/24.
////
//
//import Foundation
//import SwiftUI
// 
//final class NVRConfig: ObservableObject  {
//    
//    var https = false
//    var url = "0.0.0.1"
//    var port = "5000"
//    
//    let api = APIRequester()
//    static let _shared = NVRConfig() 
//    
//    @AppStorage("nvrIsHttps") var httpsNVR: Bool = true
//    @AppStorage("nvrIPAddress") var urlNVR: String = "0.0.0.0"
//    @AppStorage("nvrPortAddress") var portNVR: String = "5000"
//      
//    @AppStorage("frigateIsHttps") var httpsFrigate: Bool = true
//    @AppStorage("frigateIPAddress") var urlFrigate: String = "0.0.0.0"
//    @AppStorage("frigatePortAddress") var portFrigate: String = "8971"
//    
//    @AppStorage("bearerIsHttps") var httpsJWTBearer: Bool = true
//    @AppStorage("bearerIPAddress") var urlJWTBearer: String = "0.0.0.0"
//    @AppStorage("bearerPortAddress") var portJWTBearer: String = "5000"
//     
//    @AppStorage("authType") private var authType: AuthType = .none
//    @Published var tmpAuthType: AuthType = .none {
//        didSet {
//            authType = tmpAuthType // Update AppStorage when authType changes
//        }
//    }
// 
//    @Published var connectionState: NVRConnectionState = .disconnected {
//        willSet {
//            objectWillChange.send()
//        }
//    }
//    
//    class func shared() -> NVRConfig {
//        return _shared
//    }
//    
//    init() {
//        self.tmpAuthType = authType
//        self.url = self.getInitIP()
//        //self.https = self.getInitHttps()
//        self.port = getInitPort()
//    }
//    private func getInitIP() -> String {
//        switch authType{
//        case .none:
//            return  urlNVR
//        case .bearer:
//            return urlJWTBearer
//        case .frigate:
//            return urlFrigate
//        case .cloudflare:
//            return ""
//        case .custom:
//            return ""
//        }
//    }
//    private func getInitPort() -> String {
//        switch authType{
//        case .none:
//            return  portNVR
//        case .bearer:
//            return portJWTBearer
//        case .frigate:
//            return portFrigate
//        case .cloudflare:
//            return ""
//        case .custom:
//            return ""
//        }
//    }
//    
//    private func getInitHttps() -> Bool {
//        switch authType{
//        case .none:
//            if httpsNVR {
//                return true
//            } else {
//                return false
//            }
//        case .bearer:
//            if httpsJWTBearer {
//                return true
//            } else {
//                return false
//            }
//        case .frigate:
//            if httpsFrigate {
//                return true
//            } else {
//                return false
//            }
//        case .cloudflare:
//            // do nothing
//            return true
//        case .custom:
//            // do nothing
//            return true
//        }
//    }
//    
//    func getAuthType() -> AuthType{
//        return authType
//    }
//    
//    func setAuthType(authType: AuthType) {
//        self.authType = authType
//    }
//    
//    func setHttps(http:Bool) {
//         
//        switch authType{
//        case .none:
//            self.https = httpsNVR
//        case .bearer:
//            self.https = httpsJWTBearer
//        case .frigate:
//            self.https = httpsFrigate
//        case .cloudflare:
//            break
//            // do nothing
//        case .custom:
//            break
//            // do nothing
//        }
//        //self.https = http
//    }
//     
//    func setIP(ip:String) {
//        switch authType{
//        case .none:
//            self.url = ip
//        case .bearer:
//            self.url = urlJWTBearer
//        case .frigate:
//            self.url = urlFrigate
//        case .cloudflare:
//            break
//            // do nothing
//        case .custom:
//            break
//            // do nothing
//        }
//        //self.url = ip
//    }
//    
//    func setPort(ports:String) { 
//        
//        switch authType{
//        case .none:
//            self.port = portNVR
//        case .bearer:
//            self.port = portJWTBearer
//        case .frigate:
//            self.port = portFrigate
//        case .cloudflare:
//            break
//        case .custom:
//            break
//        }
//        //self.port = port
//    }
//    
//    func getIP() -> String {
//        return url
//    }
//    
//    func getUrl() -> String {
//        
//        var http: String {
//             
//            switch authType{
//            case .none:
//                if httpsNVR {
//                    return "https://"
//                } else {
//                    return "http://"
//                }
//            case .bearer:
//                if httpsJWTBearer {
//                    return "https://"
//                } else {
//                    return "http://"
//                }
//            case .frigate:
//                if httpsFrigate {
//                    return "https://"
//                } else {
//                    return "http://"
//                }
//            case .cloudflare:
//                // do nothing
//                return ""
//            case .custom:
//                // do nothing
//                return ""
//            }
//        }
//        
//        let url: String = http + self.url + ":" + self.port
//        //print("getUrl = \(url)")
//        return url
//    }
//    
//    func getConnectionState() -> Bool {
//        
//        var isConnected: Bool {
//            switch self.connectionState {
//            case .connected:
//                return true
//            case .disconnected:
//                return false
//            }
//        }
//        return isConnected
//    }
//}
