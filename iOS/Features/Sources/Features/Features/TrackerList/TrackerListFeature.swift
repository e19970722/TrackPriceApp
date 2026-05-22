import ComposableArchitecture
import Foundation

@Reducer
public struct TrackerListFeature {
    @ObservableState
    public struct State: Equatable {
        public var trackers: [Tracker] = []
        public var isLoading = false
        public var errorMessage: String?
        public var addTracker: AddTrackerFeature.State?
        public var selectedTracker: TrackerDetailFeature.State?
        public init() {}
    }

    public enum Action {
        case onAppear
        case trackersLoaded([Tracker])
        case loadFailed(String)
        case addTrackerButtonTapped
        case addTracker(AddTrackerFeature.Action)
        case addTrackerDismissed
        case trackerRowTapped(Tracker)
        case trackerDetail(TrackerDetailFeature.Action)
        case trackerDetailDismissed
        case deleteTracker(IndexSet)
        case trackerDeleted(UUID)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.trackers.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    do {
                        let trackers = try await apiClient.fetchTrackers()
                        await send(.trackersLoaded(trackers))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }

            case let .trackersLoaded(trackers):
                state.isLoading = false
                state.trackers = trackers
                return .none

            case let .loadFailed(msg):
                state.isLoading = false
                state.errorMessage = msg
                return .none

            case .addTrackerButtonTapped:
                state.addTracker = AddTrackerFeature.State()
                return .none

            case .addTracker(.dismiss), .addTracker(.trackerCreated):
                state.addTracker = nil
                return .run { send in
                    if let trackers = try? await apiClient.fetchTrackers() {
                        await send(.trackersLoaded(trackers))
                    }
                }

            case .addTracker:
                return .none

            case .addTrackerDismissed:
                state.addTracker = nil
                return .none

            case let .trackerRowTapped(tracker):
                state.selectedTracker = TrackerDetailFeature.State(tracker: tracker)
                return .none

            case .trackerDetail:
                return .none

            case .trackerDetailDismissed:
                state.selectedTracker = nil
                return .none

            case let .deleteTracker(indexSet):
                let ids = indexSet.map { state.trackers[$0].id }
                state.trackers.remove(atOffsets: indexSet)
                return .run { send in
                    for id in ids {
                        try? await apiClient.deleteTracker(id)
                        await send(.trackerDeleted(id))
                    }
                }

            case .trackerDeleted:
                return .none
            }
        }
        .ifLet(\.addTracker, action: \.addTracker) { AddTrackerFeature() }
        .ifLet(\.selectedTracker, action: \.trackerDetail) { TrackerDetailFeature() }
    }
}
