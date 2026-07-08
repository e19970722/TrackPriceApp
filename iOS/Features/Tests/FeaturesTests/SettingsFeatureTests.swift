import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@MainActor
@Suite("SettingsFeature")
struct SettingsFeatureTests {
    private static func makeUser(
        preferences: NotificationPreferences = .default
    ) -> User {
        User(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            email: "sam@rivers.me",
            displayName: "Sam Rivers",
            authProvider: "apple",
            subscriptionTier: "free",
            notificationPreferences: preferences
        )
    }

    @Test("Task loads the current user and seeds preferences")
    func taskLoadsUserAndPreferences() async {
        let serverPreferences = NotificationPreferences(
            priceDrops: true,
            expiringSoon: false,
            runningLow: true,
            weeklyDigest: true
        )
        let user = Self.makeUser(preferences: serverPreferences)
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchMe = { user }
        }

        await store.send(.task)
        await store.receive(\.meResponse.success) {
            $0.user = user
            $0.preferences = serverPreferences
        }
    }

    @Test("Task failure is silent and leaves default preferences")
    func taskFailureKeepsDefaults() async {
        struct FakeError: Error {}
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchMe = { throw FakeError() }
        }

        await store.send(.task)
        await store.receive(\.meResponse.failure)
    }

    @Test("Toggling a preference updates optimistically and PATCHes the full object")
    func preferenceToggleOptimisticallyUpdatesAndPatches() async {
        let user = Self.makeUser()
        var toggled = NotificationPreferences.default
        toggled.priceDrops = false
        var updatedUser = user
        updatedUser.notificationPreferences = toggled

        let sentPreferences = LockIsolated<NotificationPreferences?>(nil)
        var initialState = SettingsFeature.State()
        initialState.user = user
        initialState.preferences = user.notificationPreferences

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.updateNotificationPreferences = { preferences in
                sentPreferences.setValue(preferences)
                return updatedUser
            }
        }

        await store.send(.preferenceToggled(toggled)) {
            $0.preferences = toggled
        }
        await store.receive(\.preferencesUpdateResponse.success) {
            $0.user = updatedUser
        }
        #expect(sentPreferences.value == toggled)
    }

    @Test("A failed preference update silently reverts to the last-known server values")
    func preferenceToggleFailureReverts() async {
        struct FakeError: Error {}
        let user = Self.makeUser()
        var toggled = NotificationPreferences.default
        toggled.weeklyDigest = true

        var initialState = SettingsFeature.State()
        initialState.user = user
        initialState.preferences = user.notificationPreferences

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.updateNotificationPreferences = { _ in throw FakeError() }
        }

        await store.send(.preferenceToggled(toggled)) {
            $0.preferences = toggled
        }
        await store.receive(\.preferencesUpdateResponse.failure) {
            $0.preferences = user.notificationPreferences
        }
    }

    @Test("Tapping an account row pushes its destination and dismissal clears it")
    func rowTappedSetsDestination() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.rowTapped(.connectedAccounts)) {
            $0.destination = .connectedAccounts
        }
        await store.send(.destinationChanged(nil)) {
            $0.destination = nil
        }
        await store.send(.rowTapped(.plan)) {
            $0.destination = .plan
        }
        await store.send(.destinationChanged(nil)) {
            $0.destination = nil
        }
    }

    @Test("Privacy policy tap presents the in-app Safari sheet")
    func privacyPolicyPresentsSafari() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.privacyPolicyTapped) {
            $0.isSafariPresented = true
        }
        await store.send(.safariPresented(false)) {
            $0.isSafariPresented = false
        }
    }

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
