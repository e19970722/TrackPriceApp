import Foundation

public enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized: "Session expired. Please sign in again."
        case .notFound: "Resource not found."
        case let .serverError(code): "Server error (\(code))."
        case let .decodingError(e): "Data error: \(e.localizedDescription)"
        case let .networkError(e): e.localizedDescription
        }
    }
}
