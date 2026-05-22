import ComposableArchitecture

@Reducer
public struct TrackerListFeature {
    @ObservableState
    public struct State: Equatable {
        public var trackers: [Tracker] = []
        public var isLoading = false
        public var addTracker: AddTrackerFeature.State?
        public init() {}
    }

    public enum Action {
        case onAppear
        case addTrackerButtonTapped
        case addTracker(AddTrackerFeature.Action)
        case addTrackerDismissed
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case .addTrackerButtonTapped:
                state.addTracker = AddTrackerFeature.State()
                return .none

            case .addTracker(.dismiss), .addTracker(.trackerCreated):
                state.addTracker = nil
                return .none

            case .addTracker:
                return .none

            case .addTrackerDismissed:
                state.addTracker = nil
                return .none
            }
        }
        .ifLet(\.addTracker, action: \.addTracker) {
            AddTrackerFeature()
        }
    }
}
