import ComposableArchitecture

@Reducer
struct TrackerListFeature {
    @ObservableState
    struct State: Equatable {
        var trackers: [Tracker] = []
        var isLoading = false
    }
    enum Action { case onAppear }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear: return .none
            }
        }
    }
}
