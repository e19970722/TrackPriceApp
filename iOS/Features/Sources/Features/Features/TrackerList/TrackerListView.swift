import ComposableArchitecture
import SwiftUI

public struct TrackerListView: View {
    @Perception.Bindable var store: StoreOf<TrackerListFeature>

    public init(store: StoreOf<TrackerListFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.trackers.isEmpty {
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
                    List(store.trackers) { tracker in
                        TrackerRowView(tracker: tracker)
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
        .sheet(isPresented: Binding(
            get: { store.addTracker != nil },
            set: { isPresented in
                if !isPresented { store.send(.addTrackerDismissed) }
            }
        )) {
            if let addStore = store.scope(state: \.addTracker, action: \.addTracker) {
                AddTrackerView(store: addStore)
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}

// MARK: - TrackerRowView

private struct TrackerRowView: View {
    let tracker: Tracker

    var body: some View {
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
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    TrackerListView(store: Store(initialState: TrackerListFeature.State()) {
        TrackerListFeature()
    })
}
