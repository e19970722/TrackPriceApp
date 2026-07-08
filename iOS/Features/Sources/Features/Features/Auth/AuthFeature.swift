import ComposableArchitecture

@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        public var errorMessage: String?

        public init(isLoading: Bool = false, errorMessage: String? = nil) {
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action {
        case appleSignInTapped
        case googleSignInTapped
        case signInCompleted(String) // JWT token
        case signInFailed(String)
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.keychainClient) var keychain

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appleSignInTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let result = try await AppleSignInHelper.requestToken()
                        let jwt = try await apiClient.signInWithApple(result.identityToken, result.fullName)
                        await send(.signInCompleted(jwt))
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .googleSignInTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let idToken = try await GoogleSignInHelper.requestToken()
                        let jwt = try await apiClient.signInWithGoogle(idToken)
                        await send(.signInCompleted(jwt))
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case let .signInCompleted(jwt):
                state.isLoading = false
                keychain.saveToken(jwt)
                return .none // AppFeature intercepts this to switch authStatus

            case let .signInFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
            }
        }
    }
}
