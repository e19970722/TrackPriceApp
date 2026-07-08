import ComposableArchitecture
import UIKit

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var userEmail: String = ""
        public var authProvider: String = "" // "apple" or "google"
        public var isSignOutConfirmationPresented: Bool = false
        public var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        public init() {}
    }

    public enum Action {
        case signOutTapped
        case signOutConfirmed
        case signOutCancelled
        case signOutConfirmationPresented(Bool)
        case openNotificationSettings
        case delegate(Delegate)

        public enum Delegate {
            case signedOut
        }
    }

    @Dependency(\.keychainClient) var keychainClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .signOutTapped:
                state.isSignOutConfirmationPresented = true
                return .none

            case .signOutConfirmed:
                state.isSignOutConfirmationPresented = false
                return .run { send in
                    keychainClient.deleteToken()
                    await send(.delegate(.signedOut))
                }

            case .signOutCancelled:
                state.isSignOutConfirmationPresented = false
                return .none

            case let .signOutConfirmationPresented(isPresented):
                state.isSignOutConfirmationPresented = isPresented
                return .none

            case .openNotificationSettings:
                return .run { _ in
                    await MainActor.run {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

            case .delegate:
                return .none
            }
        }
    }
}
