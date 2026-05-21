import ComposableArchitecture

@Reducer
public struct TrackerDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var tracker: Tracker?
        public init() {}
    }
    public enum Action { case onAppear }
    public init() {}
    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
