import ComposableArchitecture

@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading = false
        public init() {}
    }
    public enum Action { case signInWithAppleTapped, signInWithGoogleTapped }
    public init() {}
    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
