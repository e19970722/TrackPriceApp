import ComposableArchitecture
@testable import Features
import XCTest

@MainActor
final class TrackerListFeatureTests: XCTestCase {
    func testOnAppearLoadsTrackers() async {
        let store = TestStore(initialState: TrackerListFeature.State()) {
            TrackerListFeature()
        } withDependencies: { deps in
            deps.apiClient = .mock
        }
        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.trackersLoaded) { $0.isLoading = false }
    }
}
