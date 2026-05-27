import ComposableArchitecture
import SwiftUI

public struct TrackerListView: View {
    @Perception.Bindable var store: StoreOf<TrackerListFeature>

    public init(store: StoreOf<TrackerListFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                contentView
                    .navigationTitle("My Trackers")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            addTrackerButton
                        }
                    }
            }
            .sheet(item: $store.scope(state: \.addTracker, action: \.addTracker)) { addStore in
                AddTrackerView(store: addStore)
            }
            .sheet(item: $store.scope(state: \.selectedTracker, action: \.trackerDetail)) { detailStore in
                TrackerDetailView(store: detailStore)
            }
            .onAppear { store.send(.onAppear) }
        }
    }
}

// MARK: - Subviews

extension TrackerListView {

    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            loadingView
        } else if let error = store.errorMessage {
            errorView(message: error)
        } else if store.trackers.isEmpty {
            emptyStateView
        } else {
            trackerListView
        }
    }

    private var loadingView: some View {
        ProgressView("Loading trackers…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Failed to load trackers")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                store.send(.onAppear)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Trackers Yet")
                .font(.headline)
            Text("Tap + to start tracking a price.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var trackerListView: some View {
        List {
            ForEach(store.trackers) { tracker in
                Button {
                    store.send(.trackerRowTapped(tracker))
                } label: {
                    TrackerRowView(tracker: tracker)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                store.send(.deleteTracker(indexSet))
            }
        }
    }

    private var addTrackerButton: some View {
        Button {
            store.send(.addTrackerButtonTapped)
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - TrackerRowView

private struct TrackerRowView: View {
    let tracker: Tracker

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            TrackerThumbnailView(imageUrl: tracker.itemImageUrl)
            rowInfoView
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Subviews

extension TrackerRowView {

    private var rowInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            trackerNameLabel
            lastPriceLabel
            targetInfoView
        }
    }

    private var trackerNameLabel: some View {
        Text(tracker.name)
            .font(.headline)
    }

    @ViewBuilder
    private var lastPriceLabel: some View {
        if let lastPrice = tracker.lastPrice {
            Text("\(tracker.currencySymbol)\(String(format: "%.2f", lastPrice))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var targetInfoView: some View {
        HStack {
            Image(systemName: tracker.targetDirection == .below ? "arrow.down" : "arrow.up")
                .font(.caption)
            Text("Target: \(tracker.currencySymbol)\(String(format: "%.2f", tracker.targetPrice))")
                .font(.caption)
        }
        .foregroundStyle(.tertiary)
    }
}

// MARK: - Preview

#Preview {
    TrackerListView(store: Store(initialState: TrackerListFeature.State()) {
        TrackerListFeature()
    })
}
