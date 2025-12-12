//
//  Log.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 6/3/24.
//

import Foundation
import SwiftUI

// MARK: - Log Level

/// Global log level. Stored in UserDefaults under key "log_level".
enum LogLevel: String {
    case debug    // log everything
    case warning  // log warnings + errors
    case error    // log errors only
}

private let kLogLevelKey = "log_level"

/// Helper to get the current log level from UserDefaults
private func currentLogLevel() -> LogLevel {
    let raw = UserDefaults.standard.string(forKey: kLogLevelKey) ?? LogLevel.debug.rawValue
    return LogLevel(rawValue: raw) ?? .debug
}

/// Map a log "type" string (e.g. "ERROR", "WARNING", "INFO", "DEBUG")
/// to a numeric severity so we can compare.
///
/// Higher number = more severe.
private func severity(for type: String) -> Int {
    switch type.lowercased() {
    case "error":
        return 3
    case "warning", "warn":
        return 2
    case "info":
        return 1
    default:
        // treat everything else as debug/trace-level
        return 0
    }
}

/// Numeric threshold for the current global LogLevel.
///
/// - debug   => 0 (log everything)
/// - warning => 2 (log warning + error)
/// - error   => 3 (log error only)
private func thresholdForCurrentLevel() -> Int {
    switch currentLogLevel() {
    case .debug:
        return 0
    case .warning:
        return 2
    case .error:
        return 3
    }
}

// MARK: - Central logging model

/// Central logging model observed by the UI.
///
/// NOTE:
/// - All mutations of `list` are forced onto the main queue to avoid
///   data races and crashes when logging from background threads.
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

        // 1) Respect global log level
        let s = severity(for: type)
        let threshold = thresholdForCurrentLevel()
        guard s >= threshold else {
            // Below threshold for current log level; do not store it.
            #if DEBUG
            let threadDescription = Thread.isMainThread ? "main" : "background"
            Swift.print(
                "Log.SKIP [\(threadDescription)] page=\(page), fn=\(fn), type=\(type), text=\(text) (below log level)"
            )
            #endif
            return
        }

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
