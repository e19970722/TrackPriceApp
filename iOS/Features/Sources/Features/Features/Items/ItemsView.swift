import ComposableArchitecture
import SwiftUI

public struct ItemsView: View {
    @Perception.Bindable var store: StoreOf<ItemsFeature>
    private let showsHeader: Bool
    private let showsFab: Bool
    private let showsErrorToast: Bool

    public init(
        store: StoreOf<ItemsFeature>,
        showsHeader: Bool = true,
        showsFab: Bool = true,
        showsErrorToast: Bool = true
    ) {
        self.store = store
        self.showsHeader = showsHeader
        self.showsFab = showsFab
        self.showsErrorToast = showsErrorToast
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg).ignoresSafeArea()
                contentList
                    .overlay(alignment: .bottomTrailing) { optionalFab }
            }
            .overlay(alignment: .bottom) { errorToast }
            .fullScreenCover(item: $store.scope(state: \.addItem, action: \.addItem)) { addStore in
                AddExpiryTrackerView(store: addStore)
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
                .customFont(.extrabold26)
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
        if store.items.isEmpty {
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
                .customFont(.bold15)
                .foregroundStyle(Color(.ripeInk))
                .lineLimit(1)
            Text(itemSubtitle(item))
                .customFont(.medium13)
                .foregroundStyle(Color(.ripeInk3))
                .lineLimit(1)
        }
    }

    private func itemTrailingColumn(_ item: Item) -> some View {
        VStack(alignment: .trailing, spacing: RipeSpacing.s1) {
            Text(daysLeftLabel(item))
                .customFont(.bold17)
                .monospacedDigit()
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

    private var errorToast: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                if showsErrorToast, let message = store.errorMessage {
                    RipeToast(
                        message: message,
                        onDismiss: { store.send(.errorToastDismissed) },
                        onRetry: {
                            store.send(.errorToastDismissed)
                            store.send(.fetchItems)
                        }
                    )
                    .padding(.horizontal, RipeSpacing.s5)
                    .padding(.bottom, RipeSpacing.s4)
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(
                        scale: 0.9,
                        anchor: .bottom
                    )))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: store.errorMessage)
        }
    }

    private var emptyStateView: some View {
        RipeEmptyState(
            icon: "clock",
            title: L10n.Expiry.listEmptyTitle,
            message: L10n.Expiry.listEmptyMessage
        )
    }

    private var fabButton: some View {
        Button {
            store.send(.addItemButtonTapped)
        } label: {
            Image(systemName: "plus")
                .iconFont(.xxl)
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
