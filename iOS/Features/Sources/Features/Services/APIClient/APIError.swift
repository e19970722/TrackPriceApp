import Foundation

public enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Please sign in again."
        case .notFound: return "Resource not found."
        case let .serverError(code): return "Server error (\(code))."
        case let .decodingError(e): return "Data error: \(e.localizedDescription)"
        case let .networkError(e): return e.localizedDescription
        }
    }
}
