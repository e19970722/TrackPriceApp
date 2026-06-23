import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@MainActor
@Suite("TrackerList error toast")
struct TrackerListErrorToastTests {
    @Test("loadFailed surfaces the error and stops loading")
    func loadFailedSetsErrorMessage() async {
        var initial = TrackerListFeature.State()
        initial.isLoading = true
        let store = TestStore(initialState: initial) {
            TrackerListFeature()
        }
        await store.send(.loadFailed("Could not connect to the server")) {
            $0.isLoading = false
            $0.errorMessage = "Could not connect to the server"
        }
    }

    @Test("errorToastDismissed clears the error message")
    func errorToastDismissedClearsErrorMessage() async {
        var initial = TrackerListFeature.State()
        initial.errorMessage = "Could not connect to the server"
        let store = TestStore(initialState: initial) {
            TrackerListFeature()
        }
        await store.send(.errorToastDismissed) {
            $0.errorMessage = nil
        }
    }

    @Test("Retry dismisses the toast then refetches trackers")
    func retryDismissesThenRefetches() async {
        var initial = TrackerListFeature.State()
        initial.errorMessage = "Could not connect to the server"
        let store = TestStore(initialState: initial) {
            TrackerListFeature()
        } withDependencies: {
            $0.apiClient.fetchTrackers = { [] }
        }
        // Retry first dismisses the toast immediately…
        await store.send(.errorToastDismissed) {
            $0.errorMessage = nil
        }
        // …then refetches via onAppear.
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.trackersLoaded) {
            $0.isLoading = false
            $0.trackers = []
        }
    }
}
