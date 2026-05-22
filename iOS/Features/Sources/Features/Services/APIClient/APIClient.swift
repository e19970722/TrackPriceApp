import ComposableArchitecture
import Foundation

// MARK: - Request types

public struct CreateTrackerRequest: Codable {
    public let url: String
    public let name: String
    public let cssSelector: String
    public let xpath: String
    public let currencySymbol: String
    public let confirmedPrice: Double
    public let targetPrice: Double
    public let targetDirection: Tracker.TargetDirection

    public init(url: String, name: String, cssSelector: String, xpath: String,
                currencySymbol: String, confirmedPrice: Double,
                targetPrice: Double, targetDirection: Tracker.TargetDirection) {
        self.url = url; self.name = name; self.cssSelector = cssSelector
        self.xpath = xpath; self.currencySymbol = currencySymbol
        self.confirmedPrice = confirmedPrice; self.targetPrice = targetPrice
        self.targetDirection = targetDirection
    }
}

public struct UpdateTrackerRequest: Codable {
    public var name: String?
    public var targetPrice: Double?
    public var targetDirection: Tracker.TargetDirection?
    public var muteNotifications: Bool?

    public init(name: String? = nil, targetPrice: Double? = nil,
                targetDirection: Tracker.TargetDirection? = nil,
                muteNotifications: Bool? = nil) {
        self.name = name; self.targetPrice = targetPrice
        self.targetDirection = targetDirection; self.muteNotifications = muteNotifications
    }
}

// MARK: - APIClient

public struct APIClient {
    public var signInWithApple: @Sendable (String) async throws -> String
    public var signInWithGoogle: @Sendable (String) async throws -> String
    public var updateDeviceToken: @Sendable (String) async throws -> Void
    public var fetchTrackers: @Sendable () async throws -> [Tracker]
    public var createTracker: @Sendable (CreateTrackerRequest) async throws -> Tracker
    public var updateTracker: @Sendable (UUID, UpdateTrackerRequest) async throws -> Tracker
    public var deleteTracker: @Sendable (UUID) async throws -> Void
    public var fetchPriceHistory: @Sendable (UUID) async throws -> [PriceSnapshot]
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
