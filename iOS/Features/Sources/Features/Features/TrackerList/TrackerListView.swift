import ComposableArchitecture
import SwiftUI

public struct TrackerListView: View {
    @Perception.Bindable var store: StoreOf<TrackerListFeature>
    @State private var selectedSegment: Int = 1
    @State private var searchText: String = ""

    public init(store: StoreOf<TrackerListFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        headerView
                        segmentedControlView
                            .padding(.horizontal, RipeSpacing.s5)
                            .padding(.top, RipeSpacing.s3)
                        searchBarView
                            .padding(.horizontal, RipeSpacing.s5)
                            .padding(.top, RipeSpacing.s3)
                        segmentContentView
                            .padding(.top, RipeSpacing.s4)
                            .padding(.bottom, 100)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    fabButton
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

    private var segmentedControlView: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Expire Dates", icon: "clock", index: 0)
            segmentButton(title: "Prices", icon: "tag", index: 1)
        }
        .padding(RipeSpacing.s1)
        .background(Color(.ripeSurface2))
        .clipShape(Capsule())
    }

    private func segmentButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedSegment == index
        return Button {
            selectedSegment = index
        } label: {
            HStack(spacing: RipeSpacing.s1) {
                Image(systemName: icon)
                    .font(RipeFont.body(14))
                Text(title)
                    .font(RipeFont.body(14))
            }
            .foregroundStyle(isSelected ? Color(.ripeInk) : Color(.ripeInk3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, RipeSpacing.s2)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color(.ripeSurface))
                            .ripeShadow(.soft)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
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
    private var segmentContentView: some View {
        if selectedSegment == 1 {
            pricesSegmentView
        } else {
            expireDatesSegmentView
        }
    }

    @ViewBuilder
    private var pricesSegmentView: some View {
        if store.isLoading {
            loadingView
        } else if let error = store.errorMessage {
            errorView(message: error)
        } else if store.trackers.isEmpty {
            emptyStateView
        } else {
            pricesListView
        }
    }

    private var pricesListView: some View {
        VStack(spacing: RipeSpacing.s3) {
            ForEach(filteredTrackers) { tracker in
                Button {
                    store.send(.trackerRowTapped(tracker))
                } label: {
                    trackerPriceCard(tracker)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        store.send(.deleteTrackerById(tracker.id))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, RipeSpacing.s5)
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
            if let lastPrice = tracker.lastPrice {
                Text("\(tracker.currencySymbol)\(String(format: "%.2f", lastPrice))")
                    .font(RipeFont.num(17))
                    .foregroundStyle(Color(.ripeInk))
            } else {
                Text("—")
                    .font(RipeFont.num(17))
                    .foregroundStyle(Color(.ripeInk3))
            }
            DirectionBadge(direction: tracker.targetDirection)
        }
    }

    private var expireDatesSegmentView: some View {
        VStack(spacing: RipeSpacing.s3) {
            ForEach(expireMockItems, id: \.name) { item in
                expireDateCard(item)
            }
        }
        .padding(.horizontal, RipeSpacing.s5)
    }

    private func expireDateCard(_ item: ExpireItem) -> some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                MonoThumbnail(
                    label: item.name,
                    categoryColor: Color(.ripeCat2),
                    size: 50,
                    systemImage: "refrigerator"
                )
                expireInfoColumn(item)
                Spacer(minLength: 0)
                expireTrailingColumn(item)
            }
        }
    }

    private func expireInfoColumn(_ item: ExpireItem) -> some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(item.name)
                .font(RipeFont.heading(16))
                .foregroundStyle(Color(.ripeInk))
            Text(item.subtitle)
                .font(RipeFont.caption(13))
                .foregroundStyle(Color(.ripeInk3))
        }
    }

    private func expireTrailingColumn(_ item: ExpireItem) -> some View {
        VStack(alignment: .trailing, spacing: RipeSpacing.s1) {
            Text("\(item.daysLeft)d")
                .font(RipeFont.num(17))
                .foregroundStyle(Color(.ripeInk))
            UrgencyBar(daysLeft: item.daysLeft)
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
            store.send(.addTrackerButtonTapped)
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
        let priceText: String
        if let lastPrice = tracker.lastPrice {
            priceText = "\(tracker.currencySymbol)\(String(format: "%.2f", lastPrice))"
        } else {
            priceText = "No data"
        }
        let domain = URL(string: tracker.url)?.host ?? tracker.url
        return "\(priceText) \u{00B7} \(domain)"
    }
}

// MARK: - Mock Data

private struct ExpireItem {
    let name: String
    let subtitle: String
    let daysLeft: Int
}

extension TrackerListView {

    private var expireMockItems: [ExpireItem] {
        [
            ExpireItem(name: "Greek Yogurt", subtitle: "2 cups \u{00B7} Fridge", daysLeft: 2),
            ExpireItem(name: "Eggs", subtitle: "6 left \u{00B7} Fridge", daysLeft: 3),
            ExpireItem(name: "Almond Milk", subtitle: "1 L \u{00B7} Fridge", daysLeft: 6),
        ]
    }
}

// MARK: - Preview

#Preview {
    TrackerListView(store: Store(initialState: TrackerListFeature.State()) {
        TrackerListFeature()
    })
}
