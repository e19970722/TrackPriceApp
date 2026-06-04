import ComposableArchitecture

@Reducer
public struct TrackerDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var tracker: Tracker
        public var history: [PriceSnapshot] = []
        public var isLoadingHistory = false
        public init(tracker: Tracker) { self.tracker = tracker }
    }

    public enum Action {
        case onAppear
        case historyLoaded([PriceSnapshot])
        case dismiss
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingHistory = true
                let id = state.tracker.id
                return .run { send in
                    let history = await (try? apiClient.fetchPriceHistory(id)) ?? []
                    await send(.historyLoaded(history))
                }

            case let .historyLoaded(history):
                state.isLoadingHistory = false
                state.history = history
                return .none

            case .dismiss:
                return .run { _ in await dismiss() }
            }
        }
    }
}
