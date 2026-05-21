import Foundation

struct Tracker: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var cssSelector: String
    var currencySymbol: String
    var targetPrice: Double
    var targetDirection: TargetDirection
    var status: TrackerStatus
    var lastPrice: Double?
    var lastCheckedAt: Date?
    var createdAt: Date

    enum TargetDirection: String, Codable, Equatable { case below, above }
    enum TrackerStatus: String, Codable, Equatable { case active, paused, broken }
}
