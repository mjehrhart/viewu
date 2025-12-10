//
//  Helpers.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 4/2/24.
//

import Foundation

struct Helper {
    
    // MARK: - JSON / Data helpers
    
    /// Converts UTF-8 `Data` to `String`.
    /// Returns an empty string if the data is `nil` or not valid UTF-8.
    func deserializeObject(object: Data?) -> String {
        guard
            let object,
            let jsonString = String(data: object, encoding: .utf8)
        else {
            return ""
        }
        return jsonString
    }
    
    // MARK: - Date formatters (cached)
    
    // Note: DateFormatter is not thread-safe, so only use these on the main thread.
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = .current
        return formatter
    }()
    
    // MARK: - Date / time helpers
    
    /// Returns a localized medium date + short time string (e.g. "Apr 6, 2024 at 3:45 PM" in en_US).
    /// If you want to remove "at", we can switch to a custom `dateFormat`.
    func convertDateTime(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        return Self.dateTimeFormatter.string(from: date)
    }
    
    /// Returns a localized date string (medium style, e.g. "Apr 6, 2024" in en_US).
    func convertDate(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        return Self.dateFormatter.string(from: date)
    }
    
    /// Returns a localized time string (short style, e.g. "3:45 PM" in en_US).
    func convertTime(time: Double) -> String {
        let date = Date(timeIntervalSince1970: time)
        return Self.timeFormatter.string(from: date)
    }
}


// MARK: - Remove
////  Helpers.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 4/2/24.
////
//
//import Foundation
//
//struct Helper {
//    
//    func deserializeObject(object: Data?) ->  String{
//        
//        let jsonString = String(data: object!, encoding: .utf8)!
//        return jsonString
//    }
//    
//    func convertDateTime(time: Double) -> String{
//        let date = Date(timeIntervalSince1970: time)
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeStyle = DateFormatter.Style.short
//        dateFormatter.dateStyle = DateFormatter.Style.medium
//        dateFormatter.timeZone = .current
//        var localDate = dateFormatter.string(from: date)
//        localDate.replace("at", with: "")
//        return localDate
//    }
//    
//    func convertDate(time: Double) -> String{
//        let date = Date(timeIntervalSince1970: time)
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMM YYYY dd" // hh:mm a"
//        dateFormatter.timeStyle = DateFormatter.Style.none
//        dateFormatter.dateStyle = DateFormatter.Style.medium
//        dateFormatter.timeZone = .current
//        let localDate = dateFormatter.string(from: date)
//        return localDate
//    }
//    
//    func convertTime(time: Double) -> String{
//        let date = Date(timeIntervalSince1970: time)
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeStyle = DateFormatter.Style.short
//        dateFormatter.dateStyle = DateFormatter.Style.none
//        dateFormatter.timeZone = .current
//        let localDate = dateFormatter.string(from: date)
//        return localDate
//    }
//    
//}
