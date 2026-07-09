import Foundation

/// One row of `GET /trackers/trends`: price movement of a tracker over the last 7 days.
public struct TrackerTrend: Codable, Equatable, Sendable {
    public let trackerId: UUID
    public let name: String
    public let direction: PriceDirection
    /// Absolute percent change over the window (e.g. `6.2` for a 6.2% move).
    public let deltaPercent: Double
    public let currentPrice: Double

    public init(
        trackerId: UUID,
        name: String,
        direction: PriceDirection,
        deltaPercent: Double,
        currentPrice: Double
    ) {
        self.trackerId = trackerId
        self.name = name
        self.direction = direction
        self.deltaPercent = deltaPercent
        self.currentPrice = currentPrice
    }
}
