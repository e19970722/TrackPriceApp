import ComposableArchitecture

@Reducer
struct AppFeature {
    enum AuthStatus: Equatable { case authenticated, unauthenticated }

    @ObservableState
    struct State: Equatable {
        var authStatus: AuthStatus = .unauthenticated
    }

    enum Action {
        case setAuthStatus(AuthStatus)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setAuthStatus(status):
                state.authStatus = status
                return .none
            }
        }
    }
}
