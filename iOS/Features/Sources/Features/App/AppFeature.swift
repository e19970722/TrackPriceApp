import ComposableArchitecture

@Reducer
public struct AppFeature {
    public enum AuthStatus: Equatable { case authenticated, unauthenticated }

    @ObservableState
    public struct State: Equatable {
        public var authStatus: AuthStatus = .unauthenticated
        public init() {}
    }

    public enum Action {
        case setAuthStatus(AuthStatus)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setAuthStatus(status):
                state.authStatus = status
                return .none
            }
        }
    }
}
