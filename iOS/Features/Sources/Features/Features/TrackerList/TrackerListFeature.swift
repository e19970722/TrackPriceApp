import ComposableArchitecture
import Foundation

@Reducer
public struct TrackerListFeature {
    public enum Segment: Equatable {
        case trackers, items
    }

    @ObservableState
    public struct State: Equatable {
        public var trackers: [Tracker] = []
        public var isLoading = false
        public var errorMessage: String?
        @Presents public var addTracker: AddPriceTrackerFeature.State?
        @Presents public var selectedTracker: TrackerDetailFeature.State?
        public var selectedSegment: Segment = .trackers
        public var items: ItemsFeature.State = .init()
        public init() {}

        /// True when the Prices segment has no trackers to show and is neither
        /// loading nor in an error state — i.e. the full empty state applies.
        public var showsEmptyState: Bool {
            trackers.isEmpty && !isLoading && errorMessage == nil
        }
    }

    public enum Action {
        case onAppear
        case trackersLoaded([Tracker])
        case loadFailed(String)
        case errorToastDismissed
        case addTrackerButtonTapped
        case addTracker(PresentationAction<AddPriceTrackerFeature.Action>)
        case trackerRowTapped(Tracker)
        case trackerDetail(PresentationAction<TrackerDetailFeature.Action>)
        case deleteTracker(IndexSet)
        case deleteTrackerById(UUID)
        case trackerDeleted(UUID)
        case segmentChanged(Segment)
        case items(ItemsFeature.Action)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.items, action: \.items) {
            ItemsFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                // The items segment fetches its own data via ItemsView's onAppear,
                // so only fetch trackers when the trackers segment is visible.
                guard state.selectedSegment == .trackers else { return .none }
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

            case .errorToastDismissed:
                state.errorMessage = nil
                return .none

            case .addTrackerButtonTapped:
                state.addTracker = AddPriceTrackerFeature.State()
                return .none

            case .addTracker(.dismiss), .addTracker(.presented(.trackerCreated)):
                return .run { send in
                    if let trackers = try? await apiClient.fetchTrackers() {
                        await send(.trackersLoaded(trackers))
                    }
                }

            case .addTracker:
                return .none

            case let .trackerRowTapped(tracker):
                state.selectedTracker = TrackerDetailFeature.State(tracker: tracker)
                return .none

            case .trackerDetail:
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

            case let .deleteTrackerById(id):
                state.trackers.removeAll { $0.id == id }
                return .run { send in
                    try? await apiClient.deleteTracker(id)
                    await send(.trackerDeleted(id))
                }

            case .trackerDeleted:
                return .none

            case let .segmentChanged(segment):
                guard segment != state.selectedSegment else { return .none }
                state.selectedSegment = segment
                // Refetch trackers when switching back to the trackers segment,
                // mirroring how ItemsView refetches items on every appearance.
                guard segment == .trackers else { return .none }
                return .send(.onAppear)

            case .items:
                return .none
            }
        }
        .ifLet(\.$addTracker, action: \.addTracker) { AddPriceTrackerFeature() }
        .ifLet(\.$selectedTracker, action: \.trackerDetail) { TrackerDetailFeature() }
    }
}
