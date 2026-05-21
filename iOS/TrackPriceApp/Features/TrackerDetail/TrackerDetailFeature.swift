import ComposableArchitecture

@Reducer
struct TrackerDetailFeature {
    @ObservableState
    struct State: Equatable { var tracker: Tracker? }
    enum Action { case onAppear }
    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
