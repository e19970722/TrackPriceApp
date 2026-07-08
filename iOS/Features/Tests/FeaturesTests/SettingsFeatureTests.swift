import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@MainActor
@Suite("SettingsFeature")
struct SettingsFeatureTests {
    @Test("Tapping sign out presents the confirmation dialog")
    func signOutTappedPresentsConfirmation() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        await store.send(.signOutTapped) {
            $0.isSignOutConfirmationPresented = true
        }
    }

    @Test("Dialog binding dismissal resets the presentation flag")
    func bindingDismissalResetsPresentationFlag() async {
        var state = SettingsFeature.State()
        state.isSignOutConfirmationPresented = true
        let store = TestStore(initialState: state) {
            SettingsFeature()
        }
        await store.send(.signOutConfirmationPresented(false)) {
            $0.isSignOutConfirmationPresented = false
        }
    }

    @Test("Cancelling sign out dismisses the dialog")
    func cancelDismissesDialog() async {
        var state = SettingsFeature.State()
        state.isSignOutConfirmationPresented = true
        let store = TestStore(initialState: state) {
            SettingsFeature()
        }
        await store.send(.signOutCancelled) {
            $0.isSignOutConfirmationPresented = false
        }
    }

    @Test("Confirming sign out dismisses the dialog and notifies the delegate")
    func confirmSignsOut() async {
        var state = SettingsFeature.State()
        state.isSignOutConfirmationPresented = true
        let store = TestStore(initialState: state) {
            SettingsFeature()
        }
        await store.send(.signOutConfirmed) {
            $0.isSignOutConfirmationPresented = false
        }
        await store.receive(\.delegate)
    }
}
