import ComposableArchitecture

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var userName: String = "Sam"
        public init() {}
    }

    public enum Action { case onAppear }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .onAppear: .none
            }
        }
    }
}
