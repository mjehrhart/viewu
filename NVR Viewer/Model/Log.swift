//
//  Log.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import Foundation
import SwiftUI

//TODO
//@MainActor - should be @MainActor but its causing bug issues in APIRequestor
final class Log: ObservableObject {
    
    // Same singleton API as before
    static let _shared = Log()
    
    static func shared() -> Log {
        return _shared
    }
    
    // Let @Published manage objectWillChange; no manual willSet needed
    @Published var list: [LogItem] = []
     
    /// Add a log entry
    func print(page: String, fn: String, type: String, text: String) {
        let item = LogItem(
            id: UUID(),
            page: page,
            fn: fn,
            text: text,
            type: type
        )
        list.append(item)
    }
    
    /// Optional convenience alias that avoids the name `print`
    /// (Does NOT break any existing callers)
    func log(page: String, fn: String, type: String, text: String) {
        print(page: page, fn: fn, type: type, text: text)
    }
    
    func clear() {
        list.removeAll()
    }
    
    func getList() -> [LogItem] {
        list
    }
}

struct LogItem: Identifiable, Hashable {
    let id: UUID
    let page: String
    let fn: String
    let text: String
    let type: String
}
