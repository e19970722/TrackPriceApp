import ComposableArchitecture
@testable import Features
import Foundation
import SwiftUI
import Testing

@MainActor
@Suite("HomeFeature")
struct HomeFeatureTests {
    // MARK: - Fixtures

    private static let now = Date(timeIntervalSince1970: 1_750_000_000)

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private static func daysFromNow(_ days: Int) -> Date {
        now.addingTimeInterval(TimeInterval(days) * 86400)
    }

    private static func makeUser(displayName: String? = "Sam Rivers", email: String? = "sam@rivers.me") -> User {
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            email: email,
            displayName: displayName,
            authProvider: "apple",
            subscriptionTier: "free"
        )
    }

    private static func makeTracker(
        id: UUID,
        name: String = "Olive Oil",
        targetPrice: Double,
        targetDirection: TargetDirection,
        lastPrice: Double?
    ) -> Tracker {
        Tracker(
            id: id,
            name: name,
            url: "https://www.traderjoes.com/olive-oil",
            currencySymbol: "$",
            targetPrice: targetPrice,
            targetDirection: targetDirection,
            status: .active,
            itemName: "500 ml",
            itemImageUrl: nil,
            lastPrice: lastPrice,
            lastCheckedAt: nil,
            checkInterval: 60,
            nextCheckedAt: nil,
            createdAt: now
        )
    }

    private static func makeItem(
        id: UUID,
        name: String = "Greek Yogurt",
        bestBeforeDate: Date,
        isUsed: Bool = false
    ) -> Item {
        Item(
            id: id,
            name: name,
            quantity: "2 cups",
            location: .fridge,
            bestBeforeDate: bestBeforeDate,
            addedDate: now,
            isUsed: isUsed
        )
    }

    private static func makeStore(
        initialState: HomeFeature.State = HomeFeature.State(),
        me: @escaping @Sendable () async throws -> User = { makeUser() },
        trends: @escaping @Sendable () async throws -> [TrackerTrend] = { [] },
        items: @escaping @Sendable () async throws -> [Item] = { [] },
        trackers: @escaping @Sendable () async throws -> [Tracker] = { [] },
        trackTrend: @escaping @Sendable (UUID) async throws -> Tracker = { _ in
            fatalError("trackTrend not stubbed")
        }
    ) -> TestStoreOf<HomeFeature> {
        TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.apiClient.fetchMe = me
            $0.apiClient.fetchTrends = trends
            $0.apiClient.fetchItems = items
            $0.apiClient.fetchTrackers = trackers
            $0.apiClient.trackTrend = trackTrend
            $0.date = .constant(now)
            $0.calendar = utcCalendar
        }
    }

    private struct FakeError: LocalizedError {
        var errorDescription: String? {
            "Could not reach the server"
        }
    }

    // MARK: - Default empty state

    @Test("Default state has every section empty")
    func defaultStateIsEmpty() {
        let state = HomeFeature.State()
        #expect(state.userName.isEmpty)
        #expect(state.trendItems.isEmpty)
        #expect(state.expireItems.isEmpty)
        #expect(state.priceTargets.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.priceTargetHitCount == 0)
    }

    // MARK: - Load

    @Test("onAppear populates greeting and all three sections")
    func onAppearPopulatesSections() async throws {
        let trendId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
        let itemId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let trackerId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1"))
        let store = Self.makeStore(
            trends: {
                [TrackerTrend(
                    trackerId: trendId,
                    name: "Coffee",
                    direction: .up,
                    deltaPercent: 6.2,
                    currentPrice: 12.99
                )]
            },
            items: { [Self.makeItem(id: itemId, bestBeforeDate: Self.daysFromNow(2))] },
            trackers: {
                [Self.makeTracker(id: trackerId, targetPrice: 9.00, targetDirection: .below, lastPrice: 8.99)]
            }
        )

        await store.send(.onAppear)
        await store.receive(\.loadResponse) {
            $0.userName = "Sam Rivers"
            $0.trendItems = [
                .init(id: trendId, name: "Coffee", direction: .up, delta: "6%", color: Color(.ripeCat1)),
            ]
            $0.expireItems = [
                .init(
                    id: itemId,
                    name: "Greek Yogurt",
                    meta: "2 cups · Fridge",
                    chipLabel: "2d left",
                    color: Color(.ripeCat1)
                ),
            ]
            $0.priceTargets = [
                .init(
                    id: trackerId,
                    name: "Olive Oil",
                    store: "traderjoes.com · 500 ml",
                    currentPrice: "$8.99",
                    previousPrice: "$9.00",
                    deltaValue: "0%",
                    targetLabel: "Target was $9.00"
                ),
            ]
        }
    }

    @Test("Greeting falls back to the email prefix when display name is missing")
    func greetingFallsBackToEmailPrefix() async {
        let store = Self.makeStore(me: { Self.makeUser(displayName: nil) })

        await store.send(.onAppear)
        await store.receive(\.loadResponse) {
            $0.userName = "sam"
        }
    }

    // MARK: - Price target crossing

    @Test("Only trackers whose last price crossed the target are kept")
    func targetCrossedFiltering() async throws {
        let belowHitId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1"))
        let aboveHitId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D2"))
        let store = Self.makeStore(trackers: {
            [
                // below + lastPrice <= target → hit
                Self.makeTracker(id: belowHitId, targetPrice: 9.00, targetDirection: .below, lastPrice: 8.50),
                // below + lastPrice > target → no hit
                Self.makeTracker(id: UUID(), targetPrice: 9.00, targetDirection: .below, lastPrice: 9.01),
                // above + lastPrice >= target → hit
                Self.makeTracker(id: aboveHitId, targetPrice: 100.00, targetDirection: .above, lastPrice: 100.00),
                // above + lastPrice < target → no hit
                Self.makeTracker(id: UUID(), targetPrice: 100.00, targetDirection: .above, lastPrice: 99.99),
                // no last price → no hit
                Self.makeTracker(id: UUID(), targetPrice: 9.00, targetDirection: .below, lastPrice: nil),
            ]
        })
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.loadResponse)
        #expect(store.state.priceTargets.map(\.id) == [belowHitId, aboveHitId])
        #expect(store.state.priceTargetHitCount == 2)
    }

    // MARK: - Expiring soon

    @Test("Expiring soon keeps unused items due within 7 days, sorted ascending")
    func expiryCutoffSevenDays() async throws {
        let todayId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let weekId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C2"))
        let store = Self.makeStore(items: {
            [
                // exactly at the 7-day cutoff → kept
                Self.makeItem(id: weekId, name: "Eggs", bestBeforeDate: Self.daysFromNow(7)),
                // past the cutoff → dropped
                Self.makeItem(id: UUID(), bestBeforeDate: Self.daysFromNow(8)),
                // due today → kept, sorted first
                Self.makeItem(id: todayId, bestBeforeDate: Self.now),
                // already expired → dropped
                Self.makeItem(id: UUID(), bestBeforeDate: Self.daysFromNow(-1)),
                // marked used → dropped
                Self.makeItem(id: UUID(), bestBeforeDate: Self.daysFromNow(2), isUsed: true),
            ]
        })
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.loadResponse)
        #expect(store.state.expireItems.map(\.id) == [todayId, weekId])
        #expect(store.state.expireItems.map(\.chipLabel) == ["0d left", "7d left"])
    }

    // MARK: - Tap an On Trend item to create a tracker

    private static func makeTrend(
        id: UUID,
        name: String = "Coffee",
        direction: PriceDirection = .up,
        deltaPercent: Double = 6.0,
        currentPrice: Double = 12.99
    ) -> TrackerTrend {
        TrackerTrend(
            trackerId: id,
            name: name,
            direction: direction,
            deltaPercent: deltaPercent,
            currentPrice: currentPrice
        )
    }

    @Test("Tapping an On Trend item tracks it, then reloads Home so the new tracker appears")
    func trendItemTapCreatesTrackerAndReloads() async throws {
        let trendId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
        let createdTracker = Self.makeTracker(
            id: trendId,
            name: "Coffee",
            targetPrice: 9.00,
            targetDirection: .below,
            lastPrice: 8.99
        )
        var state = HomeFeature.State()
        state.trendItems = HomeFeature.trendItems(from: [Self.makeTrend(id: trendId)])
        let store = Self.makeStore(
            initialState: state,
            trends: { [Self.makeTrend(id: trendId)] },
            trackers: { [createdTracker] },
            trackTrend: { _ in createdTracker }
        )
        store.exhaustivity = .off

        await store.send(.trendItemTapped(trendId)) {
            $0.trackingTrendId = trendId
        }
        await store.receive(\.trendTrackResponse) {
            $0.trackingTrendId = nil
        }
        // Success refreshes every Home section via onAppear.
        await store.receive(\.onAppear)
        await store.receive(\.loadResponse)
        #expect(store.state.priceTargets.map(\.id) == [trendId])
    }

    @Test("A failed track request surfaces the error toast and clears the loading state")
    func trendItemTapFailureShowsToast() async throws {
        let trendId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
        let store = Self.makeStore(trackTrend: { _ in throw FakeError() })

        await store.send(.trendItemTapped(trendId)) {
            $0.trackingTrendId = trendId
        }
        await store.receive(\.trendTrackResponse) {
            $0.trackingTrendId = nil
            $0.errorMessage = FakeError().localizedDescription
        }
    }

    @Test("A second tap while a track request is in flight is ignored")
    func trendItemTapIgnoredWhileInFlight() async throws {
        let firstId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
        let secondId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B2"))
        let createdTracker = Self.makeTracker(
            id: firstId,
            targetPrice: 9.00,
            targetDirection: .below,
            lastPrice: 8.99
        )
        let store = Self.makeStore(trackTrend: { _ in createdTracker })
        store.exhaustivity = .off

        await store.send(.trendItemTapped(firstId)) {
            $0.trackingTrendId = firstId
        }
        // Blocked: no state change, no new effect.
        await store.send(.trendItemTapped(secondId))
        await store.receive(\.trendTrackResponse) {
            $0.trackingTrendId = nil
        }
        await store.receive(\.onAppear)
        await store.receive(\.loadResponse)
    }

    // MARK: - Detail sheets

    @Test("Tapping an expiring item presents its detail sheet")
    func expireItemTapPresentsItemDetail() async throws {
        let itemId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let item = Self.makeItem(id: itemId, bestBeforeDate: Self.daysFromNow(2))
        var state = HomeFeature.State()
        state.items = [item]
        let store = Self.makeStore(initialState: state)

        await store.send(.expireItemTapped(itemId)) {
            $0.selectedItem = ItemDetailFeature.State(item: item)
        }
    }

    @Test("Tapping a price target presents its tracker detail sheet")
    func priceTargetTapPresentsTrackerDetail() async throws {
        let trackerId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1"))
        let tracker = Self.makeTracker(
            id: trackerId,
            targetPrice: 9.00,
            targetDirection: .below,
            lastPrice: 8.99
        )
        var state = HomeFeature.State()
        state.trackers = [tracker]
        let store = Self.makeStore(initialState: state)

        await store.send(.priceTargetTapped(trackerId)) {
            $0.selectedTracker = TrackerDetailFeature.State(tracker: tracker)
        }
    }

    @Test("Tapping a row whose id is not in the fetched models is a no-op")
    func unknownRowIdTapIsNoOp() async {
        let store = Self.makeStore()

        await store.send(.expireItemTapped(UUID()))
        await store.send(.priceTargetTapped(UUID()))
    }

    @Test("Deleting an item from the detail sheet dismisses it and reloads Home")
    func itemDeletedDelegateDismissesAndReloads() async throws {
        let itemId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let item = Self.makeItem(id: itemId, bestBeforeDate: Self.daysFromNow(2))
        var state = HomeFeature.State()
        state.items = [item]
        state.selectedItem = ItemDetailFeature.State(item: item)
        let store = Self.makeStore(initialState: state)
        store.exhaustivity = .off

        await store.send(.selectedItem(.presented(.delegate(.itemDeleted)))) {
            $0.selectedItem = nil
        }
        await store.receive(\.onAppear)
        await store.receive(\.loadResponse) {
            $0.items = []
            $0.expireItems = []
        }
    }

    @Test("Updating an item from the detail sheet reloads Home without dismissing")
    func itemUpdatedDelegateReloads() async throws {
        let itemId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let item = Self.makeItem(id: itemId, bestBeforeDate: Self.daysFromNow(2))
        var state = HomeFeature.State()
        state.selectedItem = ItemDetailFeature.State(item: item)
        let store = Self.makeStore(initialState: state)
        store.exhaustivity = .off

        await store.send(.selectedItem(.presented(.delegate(.itemUpdated(item)))))
        await store.receive(\.onAppear)
        await store.receive(\.loadResponse)
        #expect(store.state.selectedItem != nil)
    }

    // MARK: - Failure handling

    @Test("A single failed fetch sets the error toast but keeps the sections that loaded")
    func partialFailureShowsToastAndKeepsSuccesses() async {
        let store = Self.makeStore(trends: { throw FakeError() })

        await store.send(.onAppear)
        await store.receive(\.loadResponse) {
            $0.userName = "Sam Rivers"
            $0.errorMessage = FakeError().localizedDescription
        }
    }

    @Test("Dismissing the error toast clears the message")
    func errorToastDismissClears() async {
        var state = HomeFeature.State()
        state.errorMessage = "Could not reach the server"

        let store = TestStore(initialState: state) {
            HomeFeature()
        }

        await store.send(.errorToastDismissed) {
            $0.errorMessage = nil
        }
    }

    // MARK: - Filled sample state

    @Test("Sample state populates every section")
    func sampleStateIsFilled() {
        let state = HomeFeature.State.sample
        #expect(state.trendItems.count == 5)
        #expect(state.expireItems.count == 2)
        #expect(state.priceTargets.count == 1)
        #expect(state.priceTargetHitCount == 1)
        #expect(L10n.Home.priceTargetHits(state.priceTargetHitCount) == "1 hits")
    }
}
