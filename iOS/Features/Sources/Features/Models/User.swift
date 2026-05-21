import Foundation

public struct User: Codable, Equatable {
    public let id: UUID
    public var email: String?
    public var displayName: String?
    public var subscriptionTier: String
}
