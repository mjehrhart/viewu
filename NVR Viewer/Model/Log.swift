//
//  Log.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import Foundation
import SwiftUI

/// Central logging model observed by the UI.
///
/// NOTE:
/// - All mutations of `list` are forced onto the main queue to avoid
///   data races and crashes (`malloc: double free`, etc.) when logging
///   from background threads (URLSession callbacks, Tasks, etc.).
final class Log: ObservableObject {

    // MARK: - Singleton

    private static let _shared = Log()

    /// Global singleton accessor
    static func shared() -> Log {
        _shared
    }

    // MARK: - State

    /// Log entries shown in the UI.
    /// Access/mutation must be on the main thread.
    @Published private(set) var list: [LogItem] = []

    // MARK: - Logging API

    /// Add a log entry.
    ///
    /// This method is safe to call from any thread; it will marshal
    /// the actual mutation onto the main queue.
    func print(page: String, fn: String, type: String, text: String) {
        let item = LogItem(
            id: UUID(),
            page: page,
            fn: fn,
            text: text,
            type: type
        )

        #if DEBUG
        let threadDescription = Thread.isMainThread ? "main" : "background"
        Swift.print(
            "Log.print [\(threadDescription)] page=\(page), fn=\(fn), type=\(type), text=\(text)"
        )
        #endif

        if Thread.isMainThread {
            list.append(item)
        } else {
            DispatchQueue.main.async {
                self.list.append(item)
            }
        }
    }


    /// Convenience alias that avoids the name `print`
    /// (keeps existing callers working).
    func log(page: String, fn: String, type: String, text: String) {
        print(page: page, fn: fn, type: type, text: text)
    }

    /// Clear all log entries.
    func clear() {
        if Thread.isMainThread {
            list.removeAll()
        } else {
            DispatchQueue.main.async {
                self.list.removeAll()
            }
        }
    }

    /// Snapshot of the current list.
    /// If you call this from a background thread, it will safely
    /// hop to the main thread to read the array.
    func getList() -> [LogItem] {
        if Thread.isMainThread {
            return list
        } else {
            var snapshot: [LogItem] = []
            DispatchQueue.main.sync {
                snapshot = self.list
            }
            return snapshot
        }
    }
}

// MARK: - Model

struct LogItem: Identifiable, Hashable {
    let id: UUID
    let page: String
    let fn: String
    let text: String
    let type: String
}

////
////  Log.swift
////  NVR Viewer
////
////  Created by Matthew Ehrhart on 6/3/24.
////
//
//import Foundation
//import SwiftUI
//
////TODO
////@MainActor - should be @MainActor but its causing bug issues in APIRequestor
//final class Log: ObservableObject {
//    
//    // Same singleton API as before
//    static let _shared = Log()
//    
//    static func shared() -> Log {
//        return _shared
//    }
//    
//    // Let @Published manage objectWillChange; no manual willSet needed
//    @Published var list: [LogItem] = []
//     
//    /// Add a log entry
//    func print(page: String, fn: String, type: String, text: String) {
//        let item = LogItem(
//            id: UUID(),
//            page: page,
//            fn: fn,
//            text: text,
//            type: type
//        )
//        list.append(item) 
//    }
//    
//    /// Optional convenience alias that avoids the name `print`
//    /// (Does NOT break any existing callers)
//    func log(page: String, fn: String, type: String, text: String) {
//        print(page: page, fn: fn, type: type, text: text)
//    }
//    
//    func clear() {
//        list.removeAll()
//    }
//    
//    func getList() -> [LogItem] {
//        list
//    }
//}
//
//struct LogItem: Identifiable, Hashable {
//    let id: UUID
//    let page: String
//    let fn: String
//    let text: String
//    let type: String
//}
