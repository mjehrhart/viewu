//
//  NotificationAuthShared.swift
//  Shared between app + NotificationServiceExtension
//

import Foundation

enum NotificationAuthShared {

    // MUST match App Group exactly in BOTH targets
    static let suiteName = "group.com.viewu.app"

    // Keys stored in UserDefaults.standard / @AppStorage (APP)
    enum StandardKey {
        static let authType = "authType"

        static let cloudFlareClientId = "cloudFlareClientId"
        static let cloudFlareSecret   = "cloudFlareSecret"

        // Cache tokens for extension use
        static let jwtBearer  = "jwtBearer"
        static let jwtFrigate = "jwtFrigate"
    }

    // Keys stored inside the App Group UserDefaults (EXT reads these)
    enum GroupKey {
        static let authType = StandardKey.authType

        static let cloudFlareClientId = StandardKey.cloudFlareClientId
        static let cloudFlareSecret   = StandardKey.cloudFlareSecret

        static let jwtBearer  = StandardKey.jwtBearer
        static let jwtFrigate = StandardKey.jwtFrigate
    }

    struct Snapshot {
        let authTypeRaw: String
        let cloudFlareClientId: String
        let cloudFlareSecret: String
        let jwtBearer: String
        let jwtFrigate: String
    }

    /// Call at app launch and whenever settings/tokens change.
    @discardableResult
    static func syncFromStandardDefaults() -> Bool {
        let standard = UserDefaults.standard

        let authTypeRaw = standard.string(forKey: StandardKey.authType) ?? "none"
        let cfId = standard.string(forKey: StandardKey.cloudFlareClientId) ?? ""
        let cfSecret = standard.string(forKey: StandardKey.cloudFlareSecret) ?? ""

        let jwtBearer = standard.string(forKey: StandardKey.jwtBearer) ?? ""
        let jwtFrigate = standard.string(forKey: StandardKey.jwtFrigate) ?? ""

        // Here we DO pass the JWTs because this function is the "copy everything" sync point.
        return sync(
            authTypeRaw: authTypeRaw,
            cloudFlareClientId: cfId,
            cloudFlareSecret: cfSecret,
            jwtBearer: jwtBearer,
            jwtFrigate: jwtFrigate
        )
    }

    /// Writes to the App Group defaults so the NotificationServiceExtension can read.
    /// JWTs are optional so callers that don't "own" the tokens won't overwrite them.
    @discardableResult
    static func sync(
        authTypeRaw: String,
        cloudFlareClientId: String,
        cloudFlareSecret: String,
        jwtBearer: String? = nil,
        jwtFrigate: String? = nil
    ) -> Bool {

        guard let shared = UserDefaults(suiteName: suiteName) else { return false }

        shared.set(authTypeRaw, forKey: GroupKey.authType)
        shared.set(cloudFlareClientId, forKey: GroupKey.cloudFlareClientId)
        shared.set(cloudFlareSecret, forKey: GroupKey.cloudFlareSecret)

        // Only write JWTs if explicitly provided (prevents clobbering)
        if let jwtBearer = jwtBearer {
            shared.set(jwtBearer, forKey: GroupKey.jwtBearer)
        }
        if let jwtFrigate = jwtFrigate {
            shared.set(jwtFrigate, forKey: GroupKey.jwtFrigate)
        }

        // Optional; usually not needed, but fine if you want faster visibility for the extension.
        shared.synchronize()

        return true
    }

    /// Extension uses this.
    static func load() -> Snapshot? {
        guard let shared = UserDefaults(suiteName: suiteName) else { return nil }

        return Snapshot(
            authTypeRaw: shared.string(forKey: GroupKey.authType) ?? "none",
            cloudFlareClientId: shared.string(forKey: GroupKey.cloudFlareClientId) ?? "",
            cloudFlareSecret: shared.string(forKey: GroupKey.cloudFlareSecret) ?? "",
            jwtBearer: shared.string(forKey: GroupKey.jwtBearer) ?? "",
            jwtFrigate: shared.string(forKey: GroupKey.jwtFrigate) ?? ""
        )
    }
}
