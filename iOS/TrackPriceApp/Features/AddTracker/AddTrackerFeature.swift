import ComposableArchitecture

@Reducer
struct AddTrackerFeature {
    @ObservableState
    struct State: Equatable { var url: String = "" }
    enum Action { case urlChanged(String) }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .urlChanged(url):
                state.url = url
                return .none
            }
        }
    }
}
