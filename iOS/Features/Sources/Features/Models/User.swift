import Foundation

public struct User: Codable, Equatable, Sendable {
    public let id: UUID
    public var email: String?
    public var displayName: String?
    public var authProvider: String
    public var subscriptionTier: String
    public var notificationPreferences: NotificationPreferences

    public init(
        id: UUID,
        email: String? = nil,
        displayName: String? = nil,
        authProvider: String,
        subscriptionTier: String,
        notificationPreferences: NotificationPreferences = .default
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.authProvider = authProvider
        self.subscriptionTier = subscriptionTier
        self.notificationPreferences = notificationPreferences
    }
}

public struct NotificationPreferences: Codable, Equatable, Sendable {
    public var priceDrops: Bool
    public var expiringSoon: Bool
    public var runningLow: Bool
    public var weeklyDigest: Bool
    public var expiringSoonDaysBefore: Int
    public var runningLowThreshold: Int

    public init(
        priceDrops: Bool,
        expiringSoon: Bool,
        runningLow: Bool,
        weeklyDigest: Bool,
        expiringSoonDaysBefore: Int,
        runningLowThreshold: Int
    ) {
        self.priceDrops = priceDrops
        self.expiringSoon = expiringSoon
        self.runningLow = runningLow
        self.weeklyDigest = weeklyDigest
        self.expiringSoonDaysBefore = expiringSoonDaysBefore
        self.runningLowThreshold = runningLowThreshold
    }

    public static let `default` = NotificationPreferences(
        priceDrops: true,
        expiringSoon: true,
        runningLow: true,
        weeklyDigest: false,
        expiringSoonDaysBefore: 3,
        runningLowThreshold: 1
    )
}
