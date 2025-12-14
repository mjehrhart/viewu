import Foundation

enum CloudflareAccessCreds {

    static let suite = "group.com.viewu.app"

    // Canonical keys (DO NOT RENAME)
    static let idKey = "cloudFlareClientId"
    static let secretKey = "cloudFlareClientSecret"

    // Legacy (migration only)
    static let legacySecretKey = "cloudFlareSecret"

    static var appGroup: UserDefaults? { UserDefaults(suiteName: suite) }
    static var standard: UserDefaults { .standard }

    /// Source of truth rules:
    /// 1) If App Group has BOTH -> use it
    /// 2) Else if Standard has BOTH -> use it
    /// 3) Else use whatever partial values exist (no overwriting with empty)
    /// Also migrates legacy `cloudFlareSecret` -> `cloudFlareClientSecret` in Standard.
    @discardableResult
    static func getAndSync() -> (clientId: String, clientSecret: String) {

        func trim(_ s: String?) -> String {
            (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let stdId = trim(standard.string(forKey: idKey))
        var stdSecret = trim(standard.string(forKey: secretKey))
        let legacySecret = trim(standard.string(forKey: legacySecretKey))

        // One-time legacy migration (standard only)
        if stdSecret.isEmpty, !legacySecret.isEmpty {
            stdSecret = legacySecret
            standard.set(stdSecret, forKey: secretKey)
        }

        let agId = trim(appGroup?.string(forKey: idKey))
        let agSecret = trim(appGroup?.string(forKey: secretKey))

        let chosenId: String
        let chosenSecret: String

        if !agId.isEmpty, !agSecret.isEmpty {
            chosenId = agId
            chosenSecret = agSecret
        } else if !stdId.isEmpty, !stdSecret.isEmpty {
            chosenId = stdId
            chosenSecret = stdSecret
        } else {
            // Partial: prefer non-empty without clobbering
            chosenId = !agId.isEmpty ? agId : stdId
            chosenSecret = !agSecret.isEmpty ? agSecret : stdSecret
        }

        // Mirror into BOTH stores (never write empties)
        if !chosenId.isEmpty {
            standard.set(chosenId, forKey: idKey)
            appGroup?.set(chosenId, forKey: idKey)
        }
        if !chosenSecret.isEmpty {
            standard.set(chosenSecret, forKey: secretKey)
            appGroup?.set(chosenSecret, forKey: secretKey)
        }

        return (chosenId, chosenSecret)
    }

    /// The only “write” you should do from the UI Save button.
    static func set(clientId: String, clientSecret: String) {
        let id = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let secret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)

        if !id.isEmpty {
            standard.set(id, forKey: idKey)
            appGroup?.set(id, forKey: idKey)
        }
        if !secret.isEmpty {
            standard.set(secret, forKey: secretKey)
            appGroup?.set(secret, forKey: secretKey)
        }
    }
}
