import ComposableArchitecture

@Reducer
public struct TrackerDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var tracker: Tracker
        public var history: [PriceSnapshot] = []
        public var isLoadingHistory = false
        public var isRefreshingPrice = false
        public init(tracker: Tracker) { self.tracker = tracker }
    }

    public enum Action {
        case onAppear
        case historyLoaded([PriceSnapshot])
        case priceRefreshed(Tracker)
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
                state.isRefreshingPrice = true
                let id = state.tracker.id
                return .merge(
                    .run { send in
                        let history = (try? await apiClient.fetchPriceHistory(id)) ?? []
                        await send(.historyLoaded(history))
                    },
                    .run { send in
                        if let updated = try? await apiClient.fetchCurrentPrice(id) {
                            await send(.priceRefreshed(updated))
                        }
                    }
                )

            case let .historyLoaded(history):
                state.isLoadingHistory = false
                state.history = history
                return .none

            case let .priceRefreshed(updated):
                state.isRefreshingPrice = false
                state.tracker = updated
                return .none

            case .dismiss:
                return .run { _ in await dismiss() }
            }
        }
    }
}
