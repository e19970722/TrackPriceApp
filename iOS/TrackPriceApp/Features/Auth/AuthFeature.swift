import ComposableArchitecture

@Reducer
struct AuthFeature {
    @ObservableState
    struct State: Equatable { var isLoading = false }
    enum Action { case signInWithAppleTapped, signInWithGoogleTapped }
    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
