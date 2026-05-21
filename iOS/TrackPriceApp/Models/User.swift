import Foundation

struct User: Codable, Equatable {
    let id: UUID
    var email: String?
    var displayName: String?
    var subscriptionTier: String
}
