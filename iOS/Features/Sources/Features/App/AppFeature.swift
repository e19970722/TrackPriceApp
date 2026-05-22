import ComposableArchitecture

@Reducer
public struct AppFeature {
    public enum AuthStatus: Equatable { case authenticated, unauthenticated }

    @ObservableState
    public struct State: Equatable {
        public var authStatus: AuthStatus = .unauthenticated
        public var auth: AuthFeature.State = AuthFeature.State()
        public init() {}
    }

    public enum Action {
        case checkAuthStatus
        case setAuthStatus(AuthStatus)
        case auth(AuthFeature.Action)
    }

    @Dependency(\.keychainClient) var keychainClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
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
                return .none

            case .auth:
                return .none
            }
        }
    }
}
