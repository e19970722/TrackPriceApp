import ComposableArchitecture
import SwiftUI

public struct ItemsView: View {
    @Perception.Bindable var store: StoreOf<ItemsFeature>
    private let showsHeader: Bool
    private let showsFab: Bool

    public init(store: StoreOf<ItemsFeature>, showsHeader: Bool = true, showsFab: Bool = true) {
        self.store = store
        self.showsHeader = showsHeader
        self.showsFab = showsFab
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg).ignoresSafeArea()
                contentList
                    .overlay(alignment: .bottomTrailing) { optionalFab }
            }
            .fullScreenCover(item: $store.scope(state: \.addItem, action: \.addItem)) { addStore in
                AddItemFlowView(store: addStore)
            }
            .sheet(item: $store.scope(state: \.selectedItem, action: \.selectedItem)) { detailStore in
                ItemDetailView(store: detailStore)
            }
            .onAppear { store.send(.onAppear) }
        }
    }
}

// MARK: - Subviews

extension ItemsView {
    private var contentList: some View {
        List {
            if showsHeader { headerRow }
            itemsContent
            Color.clear.frame(height: 80)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var headerRow: some View {
        HStack {
            Text(L10n.Expiry.listTitle)
                .font(CustomFont.display(26))
                .foregroundStyle(Color(.ripeInk))
            Spacer()
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.top, RipeSpacing.s5)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var optionalFab: some View {
        if showsFab { fabButton }
    }

    @ViewBuilder
    private var itemsContent: some View {
        if store.isLoading {
            loadingView
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else if let error = store.errorMessage {
            errorView(message: error)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else if store.items.isEmpty {
            emptyStateView
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else {
            ForEach(store.items) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: Item) -> some View {
        Button {
            store.send(.itemRowTapped(item))
        } label: {
            itemCard(item)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: RipeSpacing.s1,
            leading: RipeSpacing.s5,
            bottom: RipeSpacing.s1,
            trailing: RipeSpacing.s5
        ))
    }

    private func itemCard(_ item: Item) -> some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                MonoThumbnail(
                    label: item.name,
                    categoryColor: freshnessColor(item.freshness),
                    size: 50,
                    systemImage: item.location == .freezer ? "snowflake" : nil
                )
                itemInfoColumn(item)
                Spacer(minLength: 0)
                itemTrailingColumn(item)
            }
        }
    }

    private func itemInfoColumn(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(item.name)
                .font(CustomFont.heading(16))
                .foregroundStyle(Color(.ripeInk))
                .lineLimit(1)
            Text(itemSubtitle(item))
                .font(CustomFont.caption(13))
                .foregroundStyle(Color(.ripeInk3))
                .lineLimit(1)
        }
    }

    private func itemTrailingColumn(_ item: Item) -> some View {
        VStack(alignment: .trailing, spacing: RipeSpacing.s1) {
            Text(daysLeftLabel(item))
                .font(CustomFont.num(17))
                .foregroundStyle(Color(.ripeInk))
            freshnessChip(item)
        }
    }

    private func freshnessChip(_ item: Item) -> some View {
        switch item.freshness {
        case .fresh:
            return RipeChip(label: "Fresh", tone: .good)
        case .expiring:
            return RipeChip(label: "Soon", tone: .warn)
        case .expired:
            return RipeChip(label: "Expired", tone: .danger)
        }
    }

    private var loadingView: some View {
        ProgressView("Loading items\u{2026}")
            .frame(maxWidth: .infinity, minHeight: 200)
            .font(CustomFont.body())
            .foregroundStyle(Color(.ripeInk2))
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: RipeSpacing.s3) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color(.ripeInk3))
            Text(L10n.Expiry.listErrorMessage)
                .font(CustomFont.heading())
                .foregroundStyle(Color(.ripeInk))
            Text(message)
                .font(CustomFont.body())
                .foregroundStyle(Color(.ripeInk2))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RipeSpacing.s5)
            Button(L10n.Common.retry) { store.send(.fetchItems) }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var emptyStateView: some View {
        VStack(spacing: RipeSpacing.s4) {
            Image(systemName: "refrigerator")
                .font(.system(size: 48))
                .foregroundStyle(Color(.ripeInk3))
            Text(L10n.Expiry.listEmptyTitle)
                .font(CustomFont.heading())
                .foregroundStyle(Color(.ripeInk))
            Text(L10n.Expiry.listEmptyMessage)
                .font(CustomFont.body())
                .foregroundStyle(Color(.ripeInk2))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var fabButton: some View {
        Button {
            store.send(.addItemButtonTapped)
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

extension ItemsView {
    private func freshnessColor(_ freshness: Freshness) -> Color {
        switch freshness {
        case .fresh:    Color(.ripeGood)
        case .expiring: Color(.ripeWarn)
        case .expired:  Color(.ripeDanger)
        }
    }

    private func itemSubtitle(_ item: Item) -> String {
        let parts = [item.quantity, item.locationLabel].compactMap { $0 }
        return parts.joined(separator: " \u{00B7} ")
    }

    private func daysLeftLabel(_ item: Item) -> String {
        let days = item.daysLeft
        if days < 0 { return "\(abs(days))d ago" }
        return "\(days)d"
    }
}

// MARK: - Preview

#Preview {
    ItemsView(store: Store(initialState: ItemsFeature.State()) { ItemsFeature() })
}
