import ComposableArchitecture

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action { case signOutTapped }
    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
