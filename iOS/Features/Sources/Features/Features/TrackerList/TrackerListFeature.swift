import ComposableArchitecture

@Reducer
public struct TrackerListFeature {
    @ObservableState
    public struct State: Equatable {
        public var trackers: [Tracker] = []
        public var isLoading = false
        public init() {}
    }
    public enum Action { case onAppear }
    public init() {}
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear: return .none
            }
        }
    }
}
