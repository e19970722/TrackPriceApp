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
            weeklyDigest: true,
            expiringSoonDaysBefore: 7,
            runningLowThreshold: 2
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

    private struct FakeError: LocalizedError {
        var errorDescription: String? {
            "Could not reach the server"
        }
    }

    @Test("Task failure surfaces the error toast and leaves default preferences")
    func taskFailureShowsToastAndKeepsDefaults() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchMe = { throw FakeError() }
        }

        await store.send(.task)
        await store.receive(\.meResponse.failure) {
            $0.errorMessage = FakeError().localizedDescription
        }
    }

    @Test("Dismissing the error toast clears the message and any stashed retry payload")
    func errorToastDismissClears() async {
        var toggled = NotificationPreferences.default
        toggled.priceDrops = false

        var state = SettingsFeature.State()
        state.errorMessage = "Could not reach the server"
        state.failedPreferencesUpdate = toggled

        let store = TestStore(initialState: state) {
            SettingsFeature()
        }

        await store.send(.errorToastDismissed) {
            $0.errorMessage = nil
            $0.failedPreferencesUpdate = nil
        }
    }

    @Test("Retry after a load failure re-fetches /users/me")
    func errorToastRetryRefetchesMe() async {
        let user = Self.makeUser()
        var state = SettingsFeature.State()
        state.errorMessage = "Could not reach the server"

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.fetchMe = { user }
        }

        await store.send(.errorToastRetryTapped) {
            $0.errorMessage = nil
        }
        await store.receive(\.meResponse.success) {
            $0.user = user
            $0.preferences = user.notificationPreferences
        }
    }

    @Test("Retry after a preference failure re-applies the attempted preferences")
    func errorToastRetryReappliesFailedPreferences() async {
        let user = Self.makeUser()
        var toggled = NotificationPreferences.default
        toggled.weeklyDigest = true
        var updatedUser = user
        updatedUser.notificationPreferences = toggled

        var state = SettingsFeature.State()
        state.user = user
        state.preferences = user.notificationPreferences
        state.errorMessage = "Could not reach the server"
        state.failedPreferencesUpdate = toggled

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.updateNotificationPreferences = { _ in updatedUser }
        }

        await store.send(.errorToastRetryTapped) {
            $0.errorMessage = nil
            $0.failedPreferencesUpdate = nil
        }
        await store.receive(\.preferencesChanged) {
            $0.preferences = toggled
        }
        await store.receive(\.preferencesUpdateResponse) {
            $0.user = updatedUser
        }
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

        await store.send(.preferencesChanged(toggled)) {
            $0.preferences = toggled
        }
        await store.receive(\.preferencesUpdateResponse) {
            $0.user = updatedUser
        }
        #expect(sentPreferences.value == toggled)
    }

    @Test("Bumping a numeric preference updates optimistically and PATCHes the full object")
    func numericPreferenceOptimisticallyUpdatesAndPatches() async {
        let user = Self.makeUser()
        var bumped = NotificationPreferences.default
        bumped.expiringSoonDaysBefore = 4
        var updatedUser = user
        updatedUser.notificationPreferences = bumped

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

        await store.send(.preferencesChanged(bumped)) {
            $0.preferences = bumped
        }
        await store.receive(\.preferencesUpdateResponse) {
            $0.user = updatedUser
        }
        #expect(sentPreferences.value == bumped)
        #expect(sentPreferences.value?.expiringSoonDaysBefore == 4)
    }

    @Test("A failed numeric preference update reverts and stashes the attempt for retry")
    func numericPreferenceFailureRevertsAndShowsToast() async {
        let user = Self.makeUser()
        var bumped = NotificationPreferences.default
        bumped.expiringSoonDaysBefore = 5

        var initialState = SettingsFeature.State()
        initialState.user = user
        initialState.preferences = user.notificationPreferences

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        } withDependencies: {
            $0.apiClient.updateNotificationPreferences = { _ in throw FakeError() }
        }

        await store.send(.preferencesChanged(bumped)) {
            $0.preferences = bumped
        }
        await store.receive(\.preferencesUpdateResponse) {
            $0.preferences = user.notificationPreferences
            $0.errorMessage = FakeError().localizedDescription
            $0.failedPreferencesUpdate = bumped
        }
    }

    @Test("A failed preference update reverts, surfaces the toast, and stashes the attempt for retry")
    func preferenceToggleFailureRevertsAndShowsToast() async {
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

        await store.send(.preferencesChanged(toggled)) {
            $0.preferences = toggled
        }
        await store.receive(\.preferencesUpdateResponse) {
            $0.preferences = user.notificationPreferences
            $0.errorMessage = FakeError().localizedDescription
            $0.failedPreferencesUpdate = toggled
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
