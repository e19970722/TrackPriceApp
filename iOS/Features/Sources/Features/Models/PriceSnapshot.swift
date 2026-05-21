import Foundation

public struct PriceSnapshot: Codable, Identifiable, Equatable {
    public let id: Int
    public let trackerId: UUID
    public let price: Double
    public let rawText: String
    public let scrapedAt: Date
}
