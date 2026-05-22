import ComposableArchitecture

@Reducer
public struct AppFeature {
    public enum AuthStatus: Equatable { case authenticated, unauthenticated }

    @ObservableState
    public struct State: Equatable {
        public var authStatus: AuthStatus = .unauthenticated
        public var auth: AuthFeature.State = AuthFeature.State()
        public var settings: SettingsFeature.State = SettingsFeature.State()
        public var isSettingsPresented: Bool = false
        public init() {}
    }

    public enum Action {
        case checkAuthStatus
        case setAuthStatus(AuthStatus)
        case auth(AuthFeature.Action)
        case settings(SettingsFeature.Action)
        case settingsButtonTapped
        case settingsDismissed
        // Notification actions
        case notificationsRequested
        case notificationPermissionResponse(Bool)
        case deviceTokenReceived(String)
        case uploadDeviceToken(String)
    }

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
                let token = keychainClient.loadToken()
                state.authStatus = token != nil ? .authenticated : .unauthenticated
                return .none

            case let .setAuthStatus(status):
                state.authStatus = status
                return .none

            case .auth(.signInCompleted):
                state.authStatus = .authenticated
                return .send(.notificationsRequested)

            case .auth:
                return .none

            case .settingsButtonTapped:
                state.isSettingsPresented = true
                return .none

            case .settingsDismissed:
                state.isSettingsPresented = false
                return .none

            case .settings(.delegate(.signedOut)):
                state.isSettingsPresented = false
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
