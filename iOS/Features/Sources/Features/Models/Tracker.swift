import Foundation

public struct Tracker: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var url: String
    public var cssSelector: String
    public var currencySymbol: String
    public var targetPrice: Double
    public var targetDirection: TargetDirection
    public var status: TrackerStatus
    public var lastPrice: Double?
    public var lastCheckedAt: Date?
    public var createdAt: Date

    public enum TargetDirection: String, Codable, Equatable { case below, above }
    public enum TrackerStatus: String, Codable, Equatable { case active, paused, broken }

    enum CodingKeys: String, CodingKey {
        case id, name, url, status
        case cssSelector = "css_selector"
        case currencySymbol = "currency_symbol"
        case targetPrice = "target_price"
        case targetDirection = "target_direction"
        case lastPrice = "last_price"
        case lastCheckedAt = "last_checked_at"
        case createdAt = "created_at"
    }
}
