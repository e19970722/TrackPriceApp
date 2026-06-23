import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@MainActor
@Suite("HomeFeature")
struct HomeFeatureTests {
    // MARK: - Default empty state

    @Test("Default state has every section empty")
    func defaultStateIsEmpty() {
        let state = HomeFeature.State()
        #expect(state.trendItems.isEmpty)
        #expect(state.expireItems.isEmpty)
        #expect(state.priceTargets.isEmpty)
    }

    @Test("Empty state reports zero price-target hits")
    func emptyHitCountIsZero() {
        let state = HomeFeature.State()
        #expect(state.priceTargetHitCount == 0)
        #expect(L10n.Home.priceTargetHits(state.priceTargetHitCount) == "0 hits")
    }

    // MARK: - Filled sample state

    @Test("Sample state populates every section")
    func sampleStateIsFilled() {
        let state = HomeFeature.State.sample
        #expect(state.trendItems.count == 5)
        #expect(state.expireItems.count == 2)
        #expect(state.priceTargets.count == 1)
    }

    @Test("Filled state reports the price-target hit count")
    func filledHitCountReflectsTargets() {
        let state = HomeFeature.State.sample
        #expect(state.priceTargetHitCount == state.priceTargets.count)
        #expect(L10n.Home.priceTargetHits(state.priceTargetHitCount) == "1 hits")
    }

    // MARK: - Reducer

    @Test("onAppear performs no state mutation or effect")
    func onAppearIsInert() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }
        await store.send(.onAppear)
    }
}
