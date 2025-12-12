//
//  Log.swift
//  NVR Viewer / Viewu
//
//  Central logging model observed by the UI.
//
//  - All mutations of `list` are forced onto the main queue to avoid
//    data races and crashes when logging from background threads.
//  - Log level + developer mode + bounded buffer are used to keep
//    logging from slowing the whole app down.
//

import Foundation
import SwiftUI

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// MARK: - Log Level

enum LogLevel: Int, Codable, CaseIterable {
    case debug   = 0
    case warning = 1
    case error   = 2

    var label: String {
        switch self {
        case .debug:   return "DEBUG"
        case .warning: return "WARNING"
        case .error:   return "ERROR"
        }
    }
}

// MARK: - Log Item

struct LogItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let timestamp: Date
    let page: String
    let fn: String
    let level: LogLevel
    let message: String

    var formatted: String {
        "[\(level.label)] page=\(page), fn=\(fn), text=\(message)"
    }
}

// MARK: - Log Singleton

final class Log: ObservableObject {

    // MARK: Singleton

    private static let _shared = Log()

    /// Global singleton accessor
    static func shared() -> Log {
        _shared
    }

    // MARK: - Published State (UI)

    /// Log entries shown in the UI.
    ///
    /// Access/mutation must be on the main thread.
    @Published private(set) var list: [LogItem] = []

    // MARK: - Configuration

    /// Maximum number of log entries kept in memory.
    private let maxEntries = 500

    /// Minimum log level that will be recorded / forwarded.
    ///
    /// - Debug builds default to `.debug` so you see everything.
    /// - Release builds default to `.warning` so users are not penalized.
    private var minLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .warning
        #endif
    }()

    /// Backing store for developer mode flag.
    private let defaults = UserDefaults.standard
    private let developerModeKey = "developerModeIsOn"

    /// Whether developer mode is enabled (tied to your existing AppStorage key).
    private var isDeveloperModeEnabled: Bool {
        defaults.bool(forKey: developerModeKey)
    }

    // MARK: - Public Configuration API

    /// Set the minimum log level at runtime (e.g. from Settings toggles).
    func setMinLevel(_ level: LogLevel) {
        minLevel = level
    }

    /// Static convenience so you can call `Log.setMinLevel(.error)` from anywhere.
    static func setMinLevel(_ level: LogLevel) {
        shared().setMinLevel(level)
    }

    /// Clear the in-memory log list (UI only).
    func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.list.removeAll()
        }
    }

    static func clear() {
        shared().clear()
    }

    // MARK: - Core Logging API

    /// Main logging function.
    ///
    /// - Parameters:
    ///   - level:   LogLevel (.debug, .warning, .error)
    ///   - page:    High-level area / screen (e.g. "EventStorage", "NVRConfig")
    ///   - fn:      Function name or operation (e.g. "createEventsTable")
    ///   - text:    Message text. You can build it however you want at call site.
    func log(
        _ level: LogLevel,
        page: String,
        fn: String,
        text: String
    ) {
        // 1. Filter by minimum level as early as possible.
        guard level.rawValue >= minLevel.rawValue else {
            return
        }

        let item = LogItem(
            timestamp: Date(),
            page: page,
            fn: fn,
            level: level,
            message: text
        )

        // 2. In-app UI log list (only if developer mode is ON).
        //if isDeveloperModeEnabled {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.list.append(item)

                if self.list.count > self.maxEntries {
                    self.list.removeFirst(self.list.count - self.maxEntries)
                }
            }
        //}

        // 3. Console output in Debug builds for convenience.
        #if DEBUG
        Swift.print(item.formatted)   // <-- use Swift.print to avoid the static Log.print
        #endif

        // 4. Forward to Crashlytics in non-Debug builds (except debug-level noise).
        #if !DEBUG
        #if canImport(FirebaseCrashlytics)
        if level != .debug {
            Crashlytics.crashlytics().log(item.formatted)
        }
        #endif
        #endif
    }

    // MARK: - Static Convenience Wrappers

    /// Static convenience entry point so you can use:
    /// `Log.shared().log(.warning, page: "EventStorage", fn: "createEventsTable", text: "...")`
    /// OR the shortcuts below.
    static func log(
        _ level: LogLevel,
        page: String,
        fn: String,
        text: String
    ) {
        shared().log(level, page: page, fn: fn, text: text)
    }

    static func debug(page: String, fn: String, _ text: String) {
        shared().log(.debug, page: page, fn: fn, text: text)
    }

    static func warning(page: String, fn: String, _ text: String) {
        shared().log(.warning, page: page, fn: fn, text: text)
    }

    static func error(page: String, fn: String, _ text: String) {
        shared().log(.error, page: page, fn: fn, text: text)
    }

    // MARK: - Backwards-Compatible "print" Wrapper (Optional)

    /// If you already have calls like:
    /// `Log.print(page: "EventStorage", fn: "createEventsTable", type: .warning, text: "...", code: 1)`
    /// you can route them through here and then gradually migrate to the new API.
    static func print(
        page: String,
        fn: String,
        type: LogLevel,
        text: String,
        code: Int? = nil
    ) {
        var message = text
        if let code {
            message += " (code: \(code))"
        }
        shared().log(type, page: page, fn: fn, text: message)
    }
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
//// MARK: - Log Level
//
///// Global log level. Stored in UserDefaults under key "log_level".
//enum LogLevel: String {
//    case debug    // log everything
//    case warning  // log warnings + errors
//    case error    // log errors only
//}
//
//private let kLogLevelKey = "log_level"
//
///// Helper to get the current log level from UserDefaults
//private func currentLogLevel() -> LogLevel {
//    let raw = UserDefaults.standard.string(forKey: kLogLevelKey) ?? LogLevel.debug.rawValue
//    return LogLevel(rawValue: raw) ?? .debug
//}
//
///// Map a log "type" string (e.g. "ERROR", "WARNING", "INFO", "DEBUG")
///// to a numeric severity so we can compare.
/////
///// Higher number = more severe.
//private func severity(for type: String) -> Int {
//    switch type.lowercased() {
//    case "error":
//        return 3
//    case "warning", "warn":
//        return 2
//    case "info":
//        return 1
//    default:
//        // treat everything else as debug/trace-level
//        return 0
//    }
//}
//
///// Numeric threshold for the current global LogLevel.
/////
///// - debug   => 0 (log everything)
///// - warning => 2 (log warning + error)
///// - error   => 3 (log error only)
//private func thresholdForCurrentLevel() -> Int {
//    switch currentLogLevel() {
//    case .debug:
//        return 0
//    case .warning:
//        return 2
//    case .error:
//        return 3
//    }
//}
//
//// MARK: - Central logging model
//
///// Central logging model observed by the UI.
/////
///// NOTE:
///// - All mutations of `list` are forced onto the main queue to avoid
/////   data races and crashes when logging from background threads.
//final class Log: ObservableObject {
//
//    // MARK: - Singleton
//
//    private static let _shared = Log()
//
//    /// Global singleton accessor
//    static func shared() -> Log {
//        _shared
//    }
//
//    // MARK: - State
//
//    /// Log entries shown in the UI.
//    /// Access/mutation must be on the main thread.
//    @Published private(set) var list: [LogItem] = []
//
//    // MARK: - Logging API
//
//    /// Add a log entry.
//    ///
//    /// This method is safe to call from any thread; it will marshal
//    /// the actual mutation onto the main queue.
//    func print(page: String, fn: String, type: String, text: String) {
//
//        // 1) Respect global log level
//        let s = severity(for: type)
//        let threshold = thresholdForCurrentLevel()
//        guard s >= threshold else {
//            // Below threshold for current log level; do not store it.
//            #if DEBUG
//            let threadDescription = Thread.isMainThread ? "main" : "background"
//            Swift.print(
//                "Log.SKIP [\(threadDescription)] page=\(page), fn=\(fn), type=\(type), text=\(text) (below log level)"
//            )
//            #endif
//            return
//        }
//
//        let item = LogItem(
//            id: UUID(),
//            page: page,
//            fn: fn,
//            text: text,
//            type: type
//        )
//
//        #if DEBUG
//        let threadDescription = Thread.isMainThread ? "main" : "background"
//        Swift.print(
//            "Log.print [\(threadDescription)] page=\(page), fn=\(fn), type=\(type), text=\(text)"
//        )
//        #endif
//
//        if Thread.isMainThread {
//            list.append(item)
//        } else {
//            DispatchQueue.main.async {
//                self.list.append(item)
//            }
//        }
//    }
//
//    /// Convenience alias that avoids the name `print`
//    func log(page: String, fn: String, type: String, text: String) {
//        print(page: page, fn: fn, type: type, text: text)
//    }
//
//    /// Clear all log entries.
//    func clear() {
//        if Thread.isMainThread {
//            list.removeAll()
//        } else {
//            DispatchQueue.main.async {
//                self.list.removeAll()
//            }
//        }
//    }
//
//    /// Snapshot of the current list.
//    func getList() -> [LogItem] {
//        if Thread.isMainThread {
//            return list
//        } else {
//            var snapshot: [LogItem] = []
//            DispatchQueue.main.sync {
//                snapshot = self.list
//            }
//            return snapshot
//        }
//    }
//}
//
//// MARK: - Model
//
//struct LogItem: Identifiable, Hashable {
//    let id: UUID
//    let page: String
//    let fn: String
//    let text: String
//    let type: String
//}
