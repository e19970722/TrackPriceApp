import ComposableArchitecture
import Foundation

// MARK: - Request types

public struct InteractionStep: Codable, Equatable {
    public let type: String
    public let locator: String
    public let role: String?
    public let rawText: String?
    public let currentPrice: Double?
    public let currencySymbol: String?

    public init(type: String, locator: String, role: String? = nil,
                rawText: String? = nil, currentPrice: Double? = nil,
                currencySymbol: String? = nil) {
        self.type = type; self.locator = locator; self.role = role
        self.rawText = rawText; self.currentPrice = currentPrice
        self.currencySymbol = currencySymbol
    }
}

public struct CreateTrackerRequest: Codable {
    public let url: String
    public let name: String
    public let interactions: [InteractionStep]
    public let currencySymbol: String
    public let confirmedPrice: Double
    public let targetPrice: Double
    public let targetDirection: TargetDirection
    public let itemImageUrl: String?

    public init(url: String, name: String, interactions: [InteractionStep],
                currencySymbol: String, confirmedPrice: Double,
                targetPrice: Double, targetDirection: TargetDirection,
                itemImageUrl: String? = nil) {
        self.url = url; self.name = name; self.interactions = interactions
        self.currencySymbol = currencySymbol; self.confirmedPrice = confirmedPrice
        self.targetPrice = targetPrice; self.targetDirection = targetDirection
        self.itemImageUrl = itemImageUrl
    }
}

public struct UpdateTrackerRequest: Codable {
    public var name: String?
    public var targetPrice: Double?
    public var targetDirection: TargetDirection?
    public var muteNotifications: Bool?

    public init(name: String? = nil, targetPrice: Double? = nil,
                targetDirection: TargetDirection? = nil,
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
