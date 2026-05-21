import Foundation

struct PriceSnapshot: Codable, Identifiable, Equatable {
    let id: Int
    let trackerId: UUID
    let price: Double
    let rawText: String
    let scrapedAt: Date
}
