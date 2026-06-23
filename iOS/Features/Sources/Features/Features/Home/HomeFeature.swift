import ComposableArchitecture
import SwiftUI

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var userName: String = "Sam"
        public var trendItems: [TrendItem] = []
        public var expireItems: [ExpireItem] = []
        public var priceTargets: [PriceTarget] = []

        public init() {}

        /// The hit count shown as the Price Reach Targets section action label.
        public var priceTargetHitCount: Int {
            priceTargets.count
        }
    }

    public enum Action { case onAppear }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear: .none
            }
        }
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
