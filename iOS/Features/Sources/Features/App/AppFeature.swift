import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature {
    public enum AuthStatus: Equatable { case authenticated, unauthenticated }

    @ObservableState
    public struct State: Equatable {
        public var authStatus: AuthStatus = .unauthenticated
        public var auth: AuthFeature.State = .init()
        public var settings: SettingsFeature.State = .init()
        public init() {}
    }

    public enum Action {
        case checkAuthStatus
        case setAuthStatus(AuthStatus)
        case auth(AuthFeature.Action)
        case settings(SettingsFeature.Action)
        case notificationsRequested
        case notificationPermissionResponse(Bool)
        case deviceTokenReceived(String)
        case uploadDeviceToken(String)
    }

    #if DEBUG
        private enum CancelID { case devTokenFetch }
    #endif

    @Dependency(\.keychainClient) var keychainClient
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .checkAuthStatus:
                if keychainClient.loadToken() != nil {
                    state.authStatus = .authenticated
                    return .none
                }
                #if DEBUG
                    return .run { send in
                        struct DevTokenResponse: Decodable { let token: String }
                        var request = URLRequest(url: URL(string: "http://127.0.0.1:8000/dev/token")!)
                        request.httpMethod = "POST"
                        guard let (data, _) = try? await URLSession.shared.data(for: request),
                              let response = try? JSONDecoder().decode(DevTokenResponse.self, from: data)
                        else { return }
                        keychainClient.saveToken(response.token)
                        await send(.setAuthStatus(.authenticated))
                    }
                    .cancellable(id: CancelID.devTokenFetch, cancelInFlight: true)
                #else
                    state.authStatus = .unauthenticated
                    return .none
                #endif

            case let .setAuthStatus(status):
                state.authStatus = status
                return .none

            case .auth(.signInCompleted):
                state.authStatus = .authenticated
                return .send(.notificationsRequested)

            case .auth:
                return .none

            case .settings(.delegate(.signedOut)):
                state.authStatus = .unauthenticated
                return .none

            case .settings:
                return .none

            case .notificationsRequested:
                return .run { send in
                    let granted = await notificationClient.requestPermission()
                    await send(.notificationPermissionResponse(granted))
                }

            case let .notificationPermissionResponse(granted):
                guard granted else { return .none }
                return .run { _ in
                    await notificationClient.registerForRemoteNotifications()
                }

            case let .deviceTokenReceived(token):
                return .send(.uploadDeviceToken(token))

            case let .uploadDeviceToken(token):
                return .run { _ in
                    try? await apiClient.updateDeviceToken(token)
                }
            }
        }
    }
}
