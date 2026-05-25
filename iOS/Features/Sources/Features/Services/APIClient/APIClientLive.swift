import ComposableArchitecture
import Foundation

// MARK: - Codecs

extension JSONEncoder {
    static let api: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        // Python serializes datetimes with "+00:00" offset; use a formatter that handles both
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatterNoFraction = ISO8601DateFormatter()
        formatterNoFraction.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = formatter.date(from: string) { return date }
            if let date = formatterNoFraction.date(from: string) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(string)"))
        }
        return d
    }()
}

// MARK: - Auth response

private struct AuthResponse: Decodable {
    let token: String
}

// MARK: - HTTP helper

private func apiRequest<T: Decodable>(
    _ method: String,
    path: String,
    body: (any Encodable)? = nil,
    token: String?,
    as type: T.Type = T.self
) async throws -> T {
    var request = URLRequest(url: Config.apiBaseURL.appending(path: path))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    if let body { request.httpBody = try JSONEncoder.api.encode(body) }

    #if DEBUG
    logRequest(request)
    #endif

    let (data, response): (Data, URLResponse)
    do {
        (data, response) = try await URLSession.shared.data(for: request)
    } catch {
        throw APIError.networkError(error)
    }
    guard let http = response as? HTTPURLResponse else {
        throw APIError.networkError(URLError(.badServerResponse))
    }

    #if DEBUG
    logResponse(http, data: data)
    #endif

    switch http.statusCode {
    case 200...299:
        do { return try JSONDecoder.api.decode(T.self, from: data) }
        catch { throw APIError.decodingError(error) }
    case 401: throw APIError.unauthorized
    case 404: throw APIError.notFound
    default: throw APIError.serverError(http.statusCode)
    }
}

private func apiRequestVoid(_ method: String, path: String, body: (any Encodable)? = nil, token: String?) async throws {
    var request = URLRequest(url: Config.apiBaseURL.appending(path: path))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    if let body { request.httpBody = try JSONEncoder.api.encode(body) }

    #if DEBUG
    logRequest(request)
    #endif

    let (data, response): (Data, URLResponse)
    do { (data, response) = try await URLSession.shared.data(for: request) }
    catch { throw APIError.networkError(error) }
    guard let http = response as? HTTPURLResponse else { return }

    #if DEBUG
    logResponse(http, data: data)
    #endif

    switch http.statusCode {
    case 200...299: return
    case 401: throw APIError.unauthorized
    case 404: throw APIError.notFound
    default: throw APIError.serverError(http.statusCode)
    }
}

#if DEBUG
private func logRequest(_ request: URLRequest) {
    print("→ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")")
    if let body = request.httpBody,
       let json = try? JSONSerialization.jsonObject(with: body),
       let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
       let text = String(data: pretty, encoding: .utf8) {
        print("  Body: \(text)")
    }
}

private func logResponse(_ response: HTTPURLResponse, data: Data) {
    print("← \(response.statusCode) \(response.url?.absoluteString ?? "")")
    if let json = try? JSONSerialization.jsonObject(with: data),
       let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
       let text = String(data: pretty, encoding: .utf8) {
        print("  Body: \(text)")
    } else if let text = String(data: data, encoding: .utf8), !text.isEmpty {
        print("  Body: \(text)")
    }
}
#endif

// MARK: - Live & Mock

extension APIClient {
    static var live: APIClient {
        @Dependency(\.keychainClient) var keychain
        return APIClient(
            signInWithApple: { idToken in
                let res: AuthResponse = try await apiRequest("POST", path: "/auth/apple", body: ["token": idToken], token: nil)
                return res.token
            },
            signInWithGoogle: { idToken in
                let res: AuthResponse = try await apiRequest("POST", path: "/auth/google", body: ["token": idToken], token: nil)
                return res.token
            },
            updateDeviceToken: { apnsToken in
                try await apiRequestVoid("PATCH", path: "/users/me", body: ["apns_token": apnsToken], token: keychain.loadToken())
            },
            fetchTrackers: {
                try await apiRequest("GET", path: "/trackers", token: keychain.loadToken(), as: [Tracker].self)
            },
            createTracker: { req in
                try await apiRequest("POST", path: "/trackers", body: req, token: keychain.loadToken(), as: Tracker.self)
            },
            updateTracker: { id, req in
                try await apiRequest("PATCH", path: "/trackers/\(id)", body: req, token: keychain.loadToken(), as: Tracker.self)
            },
            deleteTracker: { id in
                try await apiRequestVoid("DELETE", path: "/trackers/\(id)", token: keychain.loadToken())
            },
            fetchPriceHistory: { id in
                try await apiRequest("GET", path: "/trackers/\(id)/history", token: keychain.loadToken(), as: [PriceSnapshot].self)
            }
        )
    }

    static var mock: APIClient {
        APIClient(
            signInWithApple: { _ in "mock-jwt" },
            signInWithGoogle: { _ in "mock-jwt" },
            updateDeviceToken: { _ in },
            fetchTrackers: { [] },
            createTracker: { _ in fatalError("not implemented in mock") },
            updateTracker: { _, _ in fatalError("not implemented in mock") },
            deleteTracker: { _ in },
            fetchPriceHistory: { _ in [] }
        )
    }
}
