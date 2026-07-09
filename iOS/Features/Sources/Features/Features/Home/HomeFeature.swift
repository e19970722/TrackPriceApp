import ComposableArchitecture
import SwiftUI

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var userName: String = ""
        public var trendItems: [TrendItem] = []
        public var expireItems: [ExpireItem] = []
        public var priceTargets: [PriceTarget] = []
        public var errorMessage: String?

        public init() {}

        /// The hit count shown as the Price Reach Targets section action label.
        public var priceTargetHitCount: Int {
            priceTargets.count
        }
    }

    public enum Action {
        case onAppear
        case loadResponse(
            me: Result<User, any Error>,
            trends: Result<[TrackerTrend], any Error>,
            items: Result<[Item], any Error>,
            trackers: Result<[Tracker], any Error>
        )
        case errorToastDismissed
    }

    private enum CancelID {
        case load
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    async let me = apiClient.fetchMe()
                    async let trends = apiClient.fetchTrends()
                    async let items = apiClient.fetchItems()
                    async let trackers = apiClient.fetchTrackers()
                    await send(.loadResponse(
                        me: Result { try await me },
                        trends: Result { try await trends },
                        items: Result { try await items },
                        trackers: Result { try await trackers }
                    ))
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case let .loadResponse(me, trends, items, trackers):
                // Partial failure: apply every section that loaded and surface
                // a single toast for the first fetch that failed.
                if case let .success(user) = me {
                    state.userName = Self.greetingName(for: user)
                }
                if case let .success(trends) = trends {
                    state.trendItems = Self.trendItems(from: trends)
                }
                if case let .success(items) = items {
                    state.expireItems = Self.expireItems(from: items, now: now, calendar: calendar)
                }
                if case let .success(trackers) = trackers {
                    state.priceTargets = Self.priceTargets(from: trackers)
                }
                let failures: [any Error] = [
                    me.failureError, trends.failureError, items.failureError, trackers.failureError,
                ].compactMap { $0 }
                state.errorMessage = failures.first?.localizedDescription
                return .none

            case .errorToastDismissed:
                state.errorMessage = nil
                return .none
            }
        }
    }
}

// MARK: - Domain → Section Mapping

extension HomeFeature {
    /// Days ahead (inclusive) an item's best-before date may be to count as "expiring soon".
    static let expiringSoonWindowDays = 7

    static let categoryPalette: [Color] = [
        Color(.ripeCat1),
        Color(.ripeCat2),
        Color(.ripeCat3),
        Color(.ripeCat4),
        Color(.ripeCat5),
    ]

    static func categoryColor(at index: Int) -> Color {
        categoryPalette[index % categoryPalette.count]
    }

    /// Same fallback chain as the Profile tab: display name → email prefix → generic member label.
    static func greetingName(for user: User) -> String {
        if let name = user.displayName, !name.isEmpty {
            return name
        }
        if let email = user.email,
           let prefix = email.split(separator: "@").first,
           !prefix.isEmpty {
            return String(prefix)
        }
        return L10n.Settings.fallbackDisplayName
    }

    static func trendItems(from trends: [TrackerTrend]) -> [TrendItem] {
        trends.enumerated().map { index, trend in
            TrendItem(
                id: trend.trackerId,
                name: trend.name,
                direction: trend.direction,
                delta: "\(Int(trend.deltaPercent.rounded()))%",
                color: categoryColor(at: index)
            )
        }
    }

    static func expireItems(from items: [Item], now: Date, calendar: Calendar) -> [ExpireItem] {
        items
            .filter { !$0.isUsed }
            .compactMap { item -> (item: Item, daysLeft: Int)? in
                guard let days = calendar.dateComponents([.day], from: now, to: item.bestBeforeDate).day,
                      (0 ... expiringSoonWindowDays).contains(days)
                else { return nil }
                return (item, days)
            }
            .sorted { $0.item.bestBeforeDate < $1.item.bestBeforeDate }
            .enumerated()
            .map { index, entry in
                ExpireItem(
                    id: entry.item.id,
                    name: entry.item.name,
                    meta: [entry.item.quantity, entry.item.locationLabel]
                        .compactMap { $0 }
                        .joined(separator: " \u{00B7} "),
                    chipLabel: "\(entry.daysLeft)d left",
                    color: categoryColor(at: index)
                )
            }
    }

    static func priceTargets(from trackers: [Tracker]) -> [PriceTarget] {
        trackers.compactMap { tracker in
            guard let lastPrice = tracker.lastPrice, hasCrossedTarget(tracker, lastPrice: lastPrice) else {
                return nil
            }
            let target = tracker.targetPrice.priceFormatted(symbol: tracker.currencySymbol)
            return PriceTarget(
                id: tracker.id,
                name: tracker.name,
                store: storeLine(for: tracker),
                currentPrice: lastPrice.priceFormatted(symbol: tracker.currencySymbol),
                previousPrice: target,
                deltaValue: deltaPercentLabel(lastPrice: lastPrice, targetPrice: tracker.targetPrice),
                targetLabel: L10n.Home.targetWas(target)
            )
        }
    }

    private static func hasCrossedTarget(_ tracker: Tracker, lastPrice: Double) -> Bool {
        switch tracker.targetDirection {
        case .below: lastPrice <= tracker.targetPrice
        case .above: lastPrice >= tracker.targetPrice
        }
    }

    private static func deltaPercentLabel(lastPrice: Double, targetPrice: Double) -> String {
        guard targetPrice > 0 else { return "0%" }
        let percent = abs(lastPrice - targetPrice) / targetPrice * 100
        return "\(Int(percent.rounded()))%"
    }

    /// "host · item name" meta line, e.g. "traderjoes.com · 500 ml".
    private static func storeLine(for tracker: Tracker) -> String {
        var host = URL(string: tracker.url)?.host ?? ""
        if host.hasPrefix("www.") {
            host.removeFirst("www.".count)
        }
        return [host.isEmpty ? nil : host, tracker.itemName]
            .compactMap { $0 }
            .joined(separator: " \u{00B7} ")
    }
}

private extension Result {
    var failureError: Failure? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

// MARK: - Section Models

public extension HomeFeature {
    struct TrendItem: Identifiable, Equatable {
        public let id: UUID
        public let name: String
        public let direction: PriceDirection
        public let delta: String
        public let color: Color

        public init(
            id: UUID = UUID(),
            name: String,
            direction: PriceDirection,
            delta: String,
            color: Color
        ) {
            self.id = id
            self.name = name
            self.direction = direction
            self.delta = delta
            self.color = color
        }
    }

    struct ExpireItem: Identifiable, Equatable {
        public let id: UUID
        public let name: String
        public let meta: String
        public let chipLabel: String
        public let color: Color

        public init(
            id: UUID = UUID(),
            name: String,
            meta: String,
            chipLabel: String,
            color: Color
        ) {
            self.id = id
            self.name = name
            self.meta = meta
            self.chipLabel = chipLabel
            self.color = color
        }
    }

    struct PriceTarget: Identifiable, Equatable {
        public let id: UUID
        public let name: String
        public let store: String
        public let currentPrice: String
        public let previousPrice: String
        public let deltaValue: String
        public let targetLabel: String

        public init(
            id: UUID = UUID(),
            name: String,
            store: String,
            currentPrice: String,
            previousPrice: String,
            deltaValue: String,
            targetLabel: String
        ) {
            self.id = id
            self.name = name
            self.store = store
            self.currentPrice = currentPrice
            self.previousPrice = previousPrice
            self.deltaValue = deltaValue
            self.targetLabel = targetLabel
        }
    }
}

// MARK: - Sample Data

public extension HomeFeature.State {
    /// A fully-populated fixture exercising the filled layout in previews and tests.
    static var sample: Self {
        var state = Self()
        state.userName = "Sam"
        state.trendItems = HomeFeature.TrendItem.sampleList
        state.expireItems = HomeFeature.ExpireItem.sampleList
        state.priceTargets = HomeFeature.PriceTarget.sampleList
        return state
    }
}

public extension HomeFeature.TrendItem {
    static var sampleList: [HomeFeature.TrendItem] {
        [
            .init(name: "Coffee", direction: .up, delta: "6%", color: Color(.ripeCat1)),
            .init(name: "Olive Oil", direction: .down, delta: "11%", color: Color(.ripeCat2)),
            .init(name: "Eggs", direction: .up, delta: "4%", color: Color(.ripeCat3)),
            .init(name: "Butter", direction: .down, delta: "8%", color: Color(.ripeCat4)),
            .init(name: "Detergent", direction: .down, delta: "12%", color: Color(.ripeCat5)),
        ]
    }
}

public extension HomeFeature.ExpireItem {
    static var sampleList: [HomeFeature.ExpireItem] {
        [
            .init(name: "Greek Yogurt", meta: "2 cups · Fridge", chipLabel: "2d left", color: Color(.ripeCat3)),
            .init(name: "Eggs", meta: "6 left · Fridge", chipLabel: "3d left", color: Color(.ripeCat2)),
        ]
    }
}

public extension HomeFeature.PriceTarget {
    static var sampleList: [HomeFeature.PriceTarget] {
        [
            .init(
                name: "Olive Oil",
                store: "Trader Joe's · 500 ml",
                currentPrice: "$8.99",
                previousPrice: "$10.10",
                deltaValue: "11%",
                targetLabel: "Target was $9.00"
            ),
        ]
    }
}
