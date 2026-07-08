import ComposableArchitecture
import Foundation
import MessageUI
import UIKit

@Reducer
public struct SettingsFeature {
    public enum Destination: Equatable, Hashable {
        case connectedAccounts
        case plan
    }

    @ObservableState
    public struct State: Equatable {
        public var user: User?
        public var preferences: NotificationPreferences = .default
        public var destination: Destination?
        public var isMailComposerPresented: Bool = false
        public var isSafariPresented: Bool = false
        public var isSignOutConfirmationPresented: Bool = false
        public var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        public init() {}
    }

    public enum Action {
        case task
        case meResponse(Result<User, any Error>)
        case preferenceToggled(NotificationPreferences)
        case preferencesUpdateResponse(Result<User, any Error>)
        case rowTapped(Destination)
        case destinationChanged(Destination?)
        case helpTapped
        case mailComposerPresented(Bool)
        case privacyPolicyTapped
        case safariPresented(Bool)
        case signOutTapped
        case signOutConfirmed
        case signOutCancelled
        case signOutConfirmationPresented(Bool)
        case delegate(Delegate)

        public enum Delegate {
            case signedOut
        }
    }

    private enum CancelID {
        case updatePreferences
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.keychainClient) var keychainClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    await send(.meResponse(Result { try await apiClient.fetchMe() }))
                }

            case let .meResponse(.success(user)):
                state.user = user
                state.preferences = user.notificationPreferences
                return .none

            case .meResponse(.failure):
                // Silent: the header falls back to placeholders and toggles keep defaults.
                return .none

            case let .preferenceToggled(preferences):
                // Optimistic update; the PATCH always sends the full 4-key object.
                state.preferences = preferences
                return .run { send in
                    await send(.preferencesUpdateResponse(Result {
                        try await apiClient.updateNotificationPreferences(preferences)
                    }))
                }
                .cancellable(id: CancelID.updatePreferences, cancelInFlight: true)

            case let .preferencesUpdateResponse(.success(user)):
                state.user = user
                state.preferences = user.notificationPreferences
                return .none

            case .preferencesUpdateResponse(.failure):
                // Silent revert to the last-known server values.
                state.preferences = state.user?.notificationPreferences ?? .default
                return .none

            case let .rowTapped(destination):
                state.destination = destination
                return .none

            case let .destinationChanged(destination):
                state.destination = destination
                return .none

            case .helpTapped:
                if MFMailComposeViewController.canSendMail() {
                    state.isMailComposerPresented = true
                    return .none
                }
                return .run { _ in
                    await MainActor.run {
                        guard let url = Self.supportMailtoURL else { return }
                        UIApplication.shared.open(url)
                    }
                }

            case let .mailComposerPresented(isPresented):
                state.isMailComposerPresented = isPresented
                return .none

            case .privacyPolicyTapped:
                state.isSafariPresented = true
                return .none

            case let .safariPresented(isPresented):
                state.isSafariPresented = isPresented
                return .none

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

            case .delegate:
                return .none
            }
        }
    }

    private static var supportMailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Config.supportEmail
        components.queryItems = [URLQueryItem(name: "subject", value: L10n.Settings.feedbackMailSubject)]
        return components.url
    }
}
