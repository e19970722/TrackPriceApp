import ComposableArchitecture
import SwiftUI

public struct TrackerListView: View {
    @Perception.Bindable var store: StoreOf<TrackerListFeature>

    public init(store: StoreOf<TrackerListFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                Group {
                    if store.isLoading {
                        ProgressView("Loading trackers…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = store.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Failed to load trackers")
                                .font(.headline)
                            Text(error)
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
                    } else if store.trackers.isEmpty {
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
                    } else {
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
                }
                .navigationTitle("My Trackers")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            store.send(.addTrackerButtonTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
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

// MARK: - TrackerRowView

private struct TrackerRowView: View {
    let tracker: Tracker

    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = tracker.itemImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        placeholderThumbnail
                    }
                }
            } else {
                placeholderThumbnail
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tracker.name)
                    .font(.headline)
                if let lastPrice = tracker.lastPrice {
                    Text("\(tracker.currencySymbol)\(String(format: "%.2f", lastPrice))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Image(systemName: tracker.targetDirection == .below ? "arrow.down" : "arrow.up")
                        .font(.caption)
                    Text("Target: \(tracker.currencySymbol)\(String(format: "%.2f", tracker.targetPrice))")
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
            )
    }
}

// MARK: - Preview

#Preview {
    TrackerListView(store: Store(initialState: TrackerListFeature.State()) {
        TrackerListFeature()
    })
}
