import ComposableArchitecture
import Foundation

public struct APIClient {
    public var fetchTrackers: @Sendable () async throws -> [Tracker]
    public var deleteTracker: @Sendable (UUID) async throws -> Void
    public var fetchPriceHistory: @Sendable (UUID) async throws -> [PriceSnapshot]
    public var signInWithApple: @Sendable (String) async throws -> String
    public var signInWithGoogle: @Sendable (String) async throws -> String
    public var updateDeviceToken: @Sendable (String) async throws -> Void
}

extension APIClient: DependencyKey {
    public static var liveValue: APIClient { .live }
    public static var testValue: APIClient { .mock }
}

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
