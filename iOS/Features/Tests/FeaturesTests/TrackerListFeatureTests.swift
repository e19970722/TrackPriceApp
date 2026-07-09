import ComposableArchitecture
@testable import Features
import XCTest

@MainActor
final class TrackerListFeatureTests: XCTestCase {
    func testOnAppearWithTrackersSegmentLoadsTrackers() async {
        var initialState = TrackerListFeature.State()
        initialState.selectedSegment = .trackers
        let store = TestStore(initialState: initialState) {
            TrackerListFeature()
        } withDependencies: { deps in
            deps.apiClient = .mock
        }
        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.trackersLoaded) { $0.isLoading = false }
    }

    func testOnAppearWithDefaultItemsSegmentDoesNotFetchTrackers() async {
        let store = TestStore(initialState: TrackerListFeature.State()) {
            TrackerListFeature()
        } withDependencies: { deps in
            deps.apiClient = .mock
        }
        XCTAssertEqual(store.state.selectedSegment, .items)
        await store.send(.onAppear)
    }

    func testSegmentChangedToTrackersFetchesTrackers() async {
        let store = TestStore(initialState: TrackerListFeature.State()) {
            TrackerListFeature()
        } withDependencies: { deps in
            deps.apiClient = .mock
        }
        await store.send(.segmentChanged(.trackers)) { $0.selectedSegment = .trackers }
        await store.receive(\.onAppear) { $0.isLoading = true }
        await store.receive(\.trackersLoaded) { $0.isLoading = false }
    }

    func testSegmentChangedToSameSegmentDoesNotRefetch() async {
        let store = TestStore(initialState: TrackerListFeature.State()) {
            TrackerListFeature()
        } withDependencies: { deps in
            deps.apiClient = .mock
        }
        await store.send(.segmentChanged(.items))
    }
}
