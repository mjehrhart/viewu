
/*
*  FrigateCredentialStore.swift
*  NVR Viewer
*
*  Uses KeychainStore to manage Frigate credentials
*  in a single place for the app's authentication flow.
*  Created by CJ on 01/05/26.
*
*/
import Foundation

struct FrigateCredentials {
    let username: String
    let password: String
}

final class FrigateCredentialStore {
    static let shared = FrigateCredentialStore()

    private let keychain: KeychainStore

    private let usernameAccount = "frigate.username"
    private let passwordAccount = "frigate.password"
    private let tokenAccountPrefix = "frigate.token."

    private init(
        keychain: KeychainStore = KeychainStore(
            service: (Bundle.main.bundleIdentifier ?? "NVRViewer") + ".frigate"
        )
    ) {
        self.keychain = keychain
    }

    func saveCredentials(username: String, password: String) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        try keychain.save(trimmedUsername, account: usernameAccount)
        try keychain.save(password, account: passwordAccount)
    }

    func credentials() throws -> FrigateCredentials? {
        guard
            let username = try keychain.read(account: usernameAccount)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !username.isEmpty,
            let password = try keychain.read(account: passwordAccount),
            !password.isEmpty
        else {
            return nil
        }

        return FrigateCredentials(username: username, password: password)
    }

    func clearCredentials() throws {
        try keychain.delete(account: usernameAccount)
        try keychain.delete(account: passwordAccount)
    }

    func saveToken(_ token: String, forHost host: String) throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else { return }
        try keychain.save(trimmedToken, account: tokenAccount(for: host))
    }

    func token(forHost host: String) throws -> String? {
        guard
            let token = try keychain.read(account: tokenAccount(for: host))?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !token.isEmpty
        else {
            return nil
        }

        return token
    }

    func clearToken(forHost host: String) throws {
        try keychain.delete(account: tokenAccount(for: host))
    }

    private func tokenAccount(for host: String) -> String {
        tokenAccountPrefix + normalizedHostKey(host)
    }

    private func normalizedHostKey(_ host: String) -> String {
        var value = host.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value.lowercased()
    }
}