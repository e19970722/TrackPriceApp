import ComposableArchitecture
import XCTest
@testable import Features

@MainActor
final class TrackerListFeatureTests: XCTestCase {
    func testOnAppearDoesNothing() async {
        let store = TestStore(initialState: TrackerListFeature.State()) {
            TrackerListFeature()
        }
        await store.send(.onAppear)
    }
}
