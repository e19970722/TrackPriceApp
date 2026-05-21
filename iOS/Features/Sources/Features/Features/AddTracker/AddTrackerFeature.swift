import ComposableArchitecture

@Reducer
public struct AddTrackerFeature {
    @ObservableState
    public struct State: Equatable {
        public var url: String = ""
        public init() {}
    }
    public enum Action { case urlChanged(String) }
    public init() {}
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .urlChanged(url):
                state.url = url
                return .none
            }
        }
    }
}
