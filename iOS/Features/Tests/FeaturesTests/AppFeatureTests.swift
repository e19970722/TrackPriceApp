import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@MainActor
@Suite("AppFeature")
struct AppFeatureTests {
    // NOTE: The DEBUG-only dev-token branch of `.checkAuthStatus` calls
    // `URLSession.shared` against a hardcoded localhost URL inside the effect,
    // so its success/failure paths cannot be exercised deterministically from
    // a unit test (the outcome would depend on whether a local backend happens
    // to be running). The tests below cover every injectable path: the
    // keychain fast path, and `setAuthStatus` — the sole event that now flips
    // the app to `.authenticated` after a successful dev-token fetch.

    @Test("checkAuthStatus with a token already in the keychain authenticates immediately")
    func checkAuthStatusWithKeychainTokenAuthenticates() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.loadToken = { "stored-jwt" }
        }

        await store.send(.checkAuthStatus) {
            $0.authStatus = .authenticated
        }
    }

    @Test("setAuthStatus updates the auth status")
    func setAuthStatusUpdatesState() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.setAuthStatus(.authenticated)) {
            $0.authStatus = .authenticated
        }
        await store.send(.setAuthStatus(.unauthenticated)) {
            $0.authStatus = .unauthenticated
        }
    }

    @Test("Signing out from Settings returns to the auth screen")
    func settingsSignOutUnauthenticates() async {
        var state = AppFeature.State()
        state.authStatus = .authenticated
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.settings(.delegate(.signedOut))) {
            $0.authStatus = .unauthenticated
        }
    }
}
