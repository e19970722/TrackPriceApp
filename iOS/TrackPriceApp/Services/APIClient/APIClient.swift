import ComposableArchitecture
import Foundation

struct APIClient {
    var fetchTrackers: @Sendable () async throws -> [Tracker]
    var deleteTracker: @Sendable (UUID) async throws -> Void
    var fetchPriceHistory: @Sendable (UUID) async throws -> [PriceSnapshot]
    var signInWithApple: @Sendable (String) async throws -> String
    var signInWithGoogle: @Sendable (String) async throws -> String
    var updateDeviceToken: @Sendable (String) async throws -> Void
}

extension APIClient: DependencyKey {
    static var liveValue: APIClient { .live }
    static var testValue: APIClient { .mock }
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
