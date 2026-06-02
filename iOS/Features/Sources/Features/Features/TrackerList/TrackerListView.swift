import ComposableArchitecture
import SwiftUI

public struct TrackerListView: View {
    @Perception.Bindable var store: StoreOf<TrackerListFeature>
    @State private var searchText: String = ""

    public init(store: StoreOf<TrackerListFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg).ignoresSafeArea()
                trackersSegmentContent
                    .overlay(alignment: .bottomTrailing) { fabButton }
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
    private var trackersSegmentContent: some View {
        if store.selectedSegment == .trackers {
            trackerListView
        } else {
            ItemsView(store: store.scope(state: \.items, action: \.items))
        }
    }

    private var trackerListView: some View {
        List {
            headerView
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            segmentedPickerView
                .padding(.horizontal, RipeSpacing.s5)
                .padding(.top, RipeSpacing.s3)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            searchBarView
                .padding(.horizontal, RipeSpacing.s5)
                .padding(.top, RipeSpacing.s3)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            pricesContent
            Color.clear.frame(height: 80)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var headerView: some View {
        HStack {
            Text("Tracks")
                .font(RipeFont.display(26))
                .foregroundStyle(Color(.ripeInk))
            Spacer()
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.top, RipeSpacing.s5)
    }

    private var segmentedPickerView: some View {
        Picker("", selection: $store.selectedSegment.sending(\.segmentChanged)) {
            Text("Prices").tag(TrackerListFeature.Segment.trackers)
            Text("Expire Dates").tag(TrackerListFeature.Segment.items)
        }
        .pickerStyle(.segmented)
    }

    private var searchBarView: some View {
        HStack(spacing: RipeSpacing.s2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(.ripeInk3))
            TextField("Search tracks\u{2026}", text: $searchText)
                .font(RipeFont.body(14.5))
                .foregroundStyle(Color(.ripeInk))
                .tint(Color(.ripeAccent))
            Spacer(minLength: 0)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.ripeInk3))
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color(.ripeInk2))
            }
        }
        .padding(.horizontal, RipeSpacing.s4)
        .padding(.vertical, RipeSpacing.s3)
        .background(Color(.ripeSurface))
        .clipShape(Capsule())
        .ripeShadow(.soft)
    }

    @ViewBuilder
    private var pricesContent: some View {
        if store.isLoading {
            loadingView
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else if let error = store.errorMessage {
            errorView(message: error)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else if filteredTrackers.isEmpty {
            emptyStateView
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else {
            ForEach(filteredTrackers) { tracker in
                trackerRow(tracker)
            }
        }
    }

    private func trackerRow(_ tracker: Tracker) -> some View {
        Button {
            store.send(.trackerRowTapped(tracker))
        } label: {
            trackerPriceCard(tracker)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.send(.deleteTrackerById(tracker.id))
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: RipeSpacing.s1,
            leading: RipeSpacing.s5,
            bottom: RipeSpacing.s1,
            trailing: RipeSpacing.s5
        ))
    }

    private func trackerPriceCard(_ tracker: Tracker) -> some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                TrackerThumbnailView(imageUrl: tracker.itemImageUrl)
                trackerInfoColumn(tracker)
                Spacer(minLength: 0)
                trackerPriceColumn(tracker)
            }
        }
    }

    private func trackerInfoColumn(_ tracker: Tracker) -> some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            HStack(spacing: RipeSpacing.s2) {
                Text(tracker.name)
                    .font(RipeFont.heading(16))
                    .foregroundStyle(Color(.ripeInk))
                    .lineLimit(1)
                if trackerHasDealHit(tracker) {
                    RipeChip(label: "deal", tone: .good, systemImage: "checkmark")
                }
            }
            Text(trackerSubtitle(tracker))
                .font(RipeFont.caption(13))
                .foregroundStyle(Color(.ripeInk3))
                .lineLimit(1)
        }
    }

    private func trackerPriceColumn(_ tracker: Tracker) -> some View {
        VStack(alignment: .trailing, spacing: RipeSpacing.s1) {
            Text("$\(String(format: "%.2f", tracker.targetPrice))")
                .font(RipeFont.num(17))
                .foregroundStyle(Color(.ripeInk))
            DirectionBadge(direction: tracker.targetDirection)
        }
    }

    private var loadingView: some View {
        ProgressView("Loading trackers\u{2026}")
            .frame(maxWidth: .infinity, minHeight: 200)
            .font(RipeFont.body())
            .foregroundStyle(Color(.ripeInk2))
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: RipeSpacing.s3) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color(.ripeInk3))
            Text("Failed to load trackers")
                .font(RipeFont.heading())
                .foregroundStyle(Color(.ripeInk))
            Text(message)
                .font(RipeFont.body())
                .foregroundStyle(Color(.ripeInk2))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RipeSpacing.s5)
            Button("Retry") {
                store.send(.onAppear)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var emptyStateView: some View {
        VStack(spacing: RipeSpacing.s4) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color(.ripeInk3))
            Text("No Trackers Yet")
                .font(RipeFont.heading())
                .foregroundStyle(Color(.ripeInk))
            Text("Tap + to start tracking a price.")
                .font(RipeFont.body())
                .foregroundStyle(Color(.ripeInk2))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var fabButton: some View {
        Button {
            if store.selectedSegment == .trackers {
                store.send(.addTrackerButtonTapped)
            } else {
                store.send(.items(.addItemButtonTapped))
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(.ripeAccentInk))
                .frame(width: 58, height: 58)
                .background(Color(.ripeAccent))
                .clipShape(Circle())
                .shadow(color: Color(.ripeAccent).opacity(0.4), radius: 12, y: 6)
        }
        .padding(RipeSpacing.s5)
    }
}

// MARK: - Helpers

extension TrackerListView {

    private var filteredTrackers: [Tracker] {
        guard !searchText.isEmpty else { return store.trackers }
        return store.trackers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func trackerHasDealHit(_ tracker: Tracker) -> Bool {
        guard let lastPrice = tracker.lastPrice else { return false }
        switch tracker.targetDirection {
        case .below: return lastPrice <= tracker.targetPrice
        case .above: return lastPrice >= tracker.targetPrice
        }
    }

    private func trackerSubtitle(_ tracker: Tracker) -> String {
        URL(string: tracker.url)?.host ?? tracker.url
    }
}

// MARK: - Preview

#Preview {
    TrackerListView(store: Store(initialState: TrackerListFeature.State()) {
        TrackerListFeature()
    })
}
