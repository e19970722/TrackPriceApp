import ComposableArchitecture

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    public enum Action { case signOutTapped }
    public init() {}
    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
