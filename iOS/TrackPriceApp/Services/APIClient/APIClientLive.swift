import Foundation

extension APIClient {
    static var live: APIClient {
        APIClient(
            fetchTrackers: { [] },
            deleteTracker: { _ in },
            fetchPriceHistory: { _ in [] },
            signInWithApple: { _ in "" },
            signInWithGoogle: { _ in "" },
            updateDeviceToken: { _ in }
        )
    }

    static var mock: APIClient {
        APIClient(
            fetchTrackers: { [] },
            deleteTracker: { _ in },
            fetchPriceHistory: { _ in [] },
            signInWithApple: { _ in "mock-jwt" },
            signInWithGoogle: { _ in "mock-jwt" },
            updateDeviceToken: { _ in }
        )
    }
}
