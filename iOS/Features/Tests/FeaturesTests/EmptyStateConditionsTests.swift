import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@Suite("Tracks empty-state conditions")
struct EmptyStateConditionsTests {
    // MARK: - Prices (TrackerListFeature)

    @Test("Prices shows empty state when no trackers, not loading, no error")
    func pricesEmptyWhenNoTrackers() {
        var state = TrackerListFeature.State()
        state.trackers = []
        state.isLoading = false
        state.errorMessage = nil
        #expect(state.showsEmptyState)
    }

    @Test("Prices hides empty state while loading")
    func pricesNotEmptyWhileLoading() {
        var state = TrackerListFeature.State()
        state.isLoading = true
        #expect(!state.showsEmptyState)
    }

    @Test("Prices hides empty state on error")
    func pricesNotEmptyOnError() {
        var state = TrackerListFeature.State()
        state.errorMessage = "boom"
        #expect(!state.showsEmptyState)
    }

    @Test("Prices hides empty state when trackers exist")
    func pricesNotEmptyWithTrackers() {
        var state = TrackerListFeature.State()
        state.trackers = [Self.sampleTracker]
        #expect(!state.showsEmptyState)
    }

    // MARK: - Expire Dates (ItemsFeature)

    @Test("Expire Dates shows empty state when no items, not loading, no error")
    func expiryEmptyWhenNoItems() {
        let state = ItemsFeature.State()
        #expect(state.showsEmptyState)
    }

    @Test("Expire Dates hides empty state while loading")
    func expiryNotEmptyWhileLoading() {
        var state = ItemsFeature.State()
        state.isLoading = true
        #expect(!state.showsEmptyState)
    }

    @Test("Expire Dates hides empty state on error")
    func expiryNotEmptyOnError() {
        var state = ItemsFeature.State()
        state.errorMessage = "boom"
        #expect(!state.showsEmptyState)
    }

    @Test("Expire Dates hides empty state when items exist")
    func expiryNotEmptyWithItems() {
        let item = Item(name: "Milk", bestBeforeDate: Date().addingTimeInterval(86400))
        let state = ItemsFeature.State(items: [item])
        #expect(!state.showsEmptyState)
    }

    // MARK: - Localized copy

    @Test("Prices empty copy matches the design")
    func pricesCopy() {
        #expect(L10n.TrackerList.emptyTitle == "No price tracks yet")
        #expect(L10n.TrackerList.emptyMessage.contains("pick the price on the page"))
        #expect(L10n.TrackerList.emptyMessage.hasSuffix("Tap + to start."))
    }

    @Test("Prices no-results copy interpolates the query")
    func pricesNoResultsCopy() {
        #expect(L10n.TrackerList.noResults("milk") == "No matches for \u{201C}milk\u{201D}")
    }

    @Test("Expire Dates empty copy matches the design")
    func expiryCopy() {
        #expect(L10n.Expiry.listEmptyTitle == "No expiry tracks yet")
        #expect(L10n.Expiry.listEmptyMessage.contains("expiry date"))
        #expect(L10n.Expiry.listEmptyMessage.hasSuffix("Tap + to start."))
    }

    // MARK: - Fixtures

    private static let sampleTracker = Tracker(
        id: UUID(),
        name: "Sample",
        url: "https://example.com",
        currencySymbol: "$",
        targetPrice: 9.99,
        targetDirection: .below,
        status: .active,
        itemName: nil,
        itemImageUrl: nil,
        lastPrice: nil,
        lastCheckedAt: nil,
        checkInterval: 60,
        nextCheckedAt: nil,
        createdAt: Date()
    )
}
