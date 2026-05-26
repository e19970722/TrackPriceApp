import Foundation

public struct Tracker: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var url: String
    public var currencySymbol: String
    public var targetPrice: Double
    public var targetDirection: TargetDirection
    public var status: TrackerStatus
    public var lastPrice: Double?
    public var lastCheckedAt: Date?
    public var checkInterval: Int
    public var nextCheckAt: Date?
    public var createdAt: Date

    public enum TargetDirection: String, Codable, Equatable { case below, above }
    public enum TrackerStatus: String, Codable, Equatable { case active, paused, broken }
}
