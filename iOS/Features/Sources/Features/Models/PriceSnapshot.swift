import Foundation

public struct PriceSnapshot: Codable, Identifiable, Equatable {
    public let id: Int
    public let trackerId: UUID
    public let price: Double
    public let rawText: String
    public let scrapedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, price
        case trackerId = "tracker_id"
        case rawText = "raw_text"
        case scrapedAt = "scraped_at"
    }
}
