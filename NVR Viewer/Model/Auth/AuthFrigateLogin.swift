/*
*  AuthFrigateLogin.swift
*  NVR Viewer
*
*  Handles Frigate authentication using username and password, requests a login
*  token, stores it securely, and retries once if the token has expired.
*
*  Created by CJ on 01/05/26.
*
*/
import Foundation

private enum FrigateLoginError: LocalizedError {
    case missingHost
    case missingUsername
    case missingPassword
    case invalidURL(String)
    case invalidResponse
    case unauthorized
    case tokenMissing
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingHost:
            return "Missing Frigate host"
        case .missingUsername:
            return "Missing Frigate username"
        case .missingPassword:
            return "Missing Frigate password"
        case .invalidURL(let value):
            return "Invalid URL: \(value)"
        case .invalidResponse:
            return "Invalid response from Frigate login"
        case .unauthorized:
            return "Frigate login failed: unauthorized"
        case .tokenMissing:
            return "Frigate login succeeded but no token was returned"
        case .apiError(let code, let body):
            return "Frigate login failed with status \(code). \(body)"
        }
    }
}

private struct FrigateLoginRequest: Encodable {
    let user: String
    let password: String
}

final class AuthFrigateLogin {
    static let shared = AuthFrigateLogin()

    private let credentialStore = FrigateCredentialStore.shared

    private init() {}

    private func normalizedBaseURL(_ host: String) -> String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") {
            return String(trimmed.dropLast())
        }
        return trimmed
    }

    private func makeURL(base: String, endpoint: String) throws -> URL {
        let normalizedBase = normalizedBaseURL(base)
        guard !normalizedBase.isEmpty else {
            throw FrigateLoginError.missingHost
        }

        let normalizedEndpoint: String
        if endpoint.isEmpty {
            normalizedEndpoint = ""
        } else if endpoint.hasPrefix("/") {
            normalizedEndpoint = endpoint
        } else {
            normalizedEndpoint = "/" + endpoint
        }

        let urlString = normalizedBase + normalizedEndpoint
        guard let url = URL(string: urlString) else {
            throw FrigateLoginError.invalidURL(urlString)
        }
        return url
    }

    func saveCredentials(username: String, password: String) {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "saveCredentials",
                FrigateLoginError.missingUsername.localizedDescription
            )
            return
        }

        guard !password.isEmpty else {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "saveCredentials",
                FrigateLoginError.missingPassword.localizedDescription
            )
            return
        }

        do {
            try credentialStore.saveCredentials(
                username: trimmedUsername,
                password: password
            )
        } catch {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "saveCredentials",
                error.localizedDescription
            )
        }
    }

    func clearStoredCredentials() {
        do {
            try credentialStore.clearCredentials()
        } catch {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "clearStoredCredentials",
                error.localizedDescription
            )
        }
    }

    func clearStoredToken(host: String) {
        do {
            try credentialStore.clearToken(forHost: host)
        } catch {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "clearStoredToken",
                error.localizedDescription
            )
        }
    }

    func storedToken(host: String) -> String? {
        do {
            return try credentialStore.token(forHost: host)
        } catch {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "storedToken",
                error.localizedDescription
            )
            return nil
        }
    }

    func login(host: String) async throws -> String {
        guard let credentials = try credentialStore.credentials() else {
            let hasUsername = (try credentialStore.credentials()?.username) != nil
            if hasUsername {
                throw FrigateLoginError.missingPassword
            } else {
                throw FrigateLoginError.missingUsername
            }
        }

        let url = try makeURL(base: host, endpoint: "/api/login")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(
            FrigateLoginRequest(
                user: credentials.username,
                password: credentials.password
            )
        )

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true

        let delegate = FrigateURLSessionDelegate()
        let session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )

        defer {
            session.finishTasksAndInvalidate()
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw FrigateLoginError.invalidResponse
        }

        if http.statusCode == 401 {
            throw FrigateLoginError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw FrigateLoginError.apiError(http.statusCode, body)
        }

        guard let token = extractToken(from: http, data: data, url: url) else {
            throw FrigateLoginError.tokenMissing
        }

        try credentialStore.saveToken(token, forHost: host)

        Log.debug(
            page: "AuthFrigateLogin",
            fn: "login",
            "Stored Frigate-issued token in Keychain"
        )

        return token
    }

    func token(host: String, forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let existing = storedToken(host: host) {
            return existing
        }

        clearStoredToken(host: host)
        return try await login(host: host)
    }

    func connect(
        host: String,
        endpoint: String,
        forceRefresh: Bool = false,
        completion: @escaping (Data?, Error?) -> Void
    ) async {
        do {
            let token = try await token(host: host, forceRefresh: forceRefresh)

            await connectToFrigateAPIWithJWT(
                host: host,
                jwtToken: token,
                endpoint: endpoint
            ) { data, error in
                if let nsError = error as NSError?,
                   nsError.domain == "APIError",
                   nsError.code == 401,
                   !forceRefresh {
                    Log.debug(
                        page: "AuthFrigateLogin",
                        fn: "connect",
                        "401 received, clearing cached token and retrying once"
                    )

                    self.clearStoredToken(host: host)

                    Task {
                        await self.connect(
                            host: host,
                            endpoint: endpoint,
                            forceRefresh: true,
                            completion: completion
                        )
                    }
                    return
                }

                completion(data, error)
            }
        } catch {
            Log.error(
                page: "AuthFrigateLogin",
                fn: "connect",
                error.localizedDescription
            )
            completion(nil, error)
        }
    }

    private func extractToken(
        from response: HTTPURLResponse,
        data: Data,
        url: URL
    ) -> String? {
        let headerFields: [String: String] = response.allHeaderFields.reduce(into: [:]) { result, item in
            guard let key = item.key as? String else { return }
            guard let value = item.value as? String else { return }
            result[key] = value
        }

        let cookiesFromHeaders = HTTPCookie.cookies(
            withResponseHeaderFields: headerFields,
            for: url
        )
        if let token = tokenFromCookies(cookiesFromHeaders) {
            return token
        }

        if let storedCookies = HTTPCookieStorage.shared.cookies(for: url),
           let token = tokenFromCookies(storedCookies) {
            return token
        }

        if !data.isEmpty,
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["access_token", "token", "jwt", "frigate_token", "frigate-token"] {
                if let token = object[key] as? String {
                    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        return trimmed
                    }
                }
            }
        }

        return nil
    }

    private func tokenFromCookies(_ cookies: [HTTPCookie]) -> String? {
        let preferredNames: Set<String> = [
            "frigate_token",
            "frigate-token"
        ]

        if let cookie = cookies.first(where: {
            preferredNames.contains($0.name.lowercased()) &&
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            return cookie.value
        }

        if let cookie = cookies.first(where: {
            $0.name.lowercased().contains("frigate") &&
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            return cookie.value
        }

        if let cookie = cookies.first(where: {
            $0.name.lowercased().contains("token") &&
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            return cookie.value
        }

        return nil
    }
}