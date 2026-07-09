import ComposableArchitecture
import SwiftUI

public struct HomeView: View {
    let store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg)
                    .ignoresSafeArea()
                scrollContentView
            }
            .onAppear {
                store.send(.onAppear)
            }
            .overlay(alignment: .bottom) { errorToastView }
        }
    }
}

// MARK: - Subviews

extension HomeView {
    private var scrollContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: RipeSpacing.s6) {
                greetingHeaderSection
                trendTracksSection
                expireSoonSection
                priceTargetsSection
            }
            .padding(.top, RipeSpacing.s5)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    // MARK: 1 — Greeting header

    private var greetingHeaderSection: some View {
        WithPerceptionTracking {
            HStack(alignment: .center) {
                greetingTextStack
                Spacer()
                avatarThumbnailView
            }
            .padding(.horizontal, RipeSpacing.s5)
        }
    }

    private var greetingTextStack: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Home.greeting)
                    .customFont(.semibold13)
                    .foregroundStyle(Color(.ripeInk2))
                Text(store.userName)
                    .customFont(.extrabold30)
                    .foregroundStyle(Color(.ripeInk))
            }
        }
    }

    private var avatarThumbnailView: some View {
        WithPerceptionTracking {
            MonoThumbnail(
                label: userInitials,
                categoryColor: Color(.ripeAccent),
                size: 46,
                round: true
            )
        }
    }

    private var errorToastView: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                if let message = store.errorMessage {
                    RipeToast(
                        message: message,
                        onDismiss: { store.send(.errorToastDismissed) },
                        onRetry: {
                            store.send(.errorToastDismissed)
                            store.send(.onAppear)
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
            .animation(
                .spring(response: 0.35, dampingFraction: 0.7),
                value: store.errorMessage != nil
            )
        }
    }

    // MARK: 2 — On Trend Tracks

    private var trendTracksSection: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: RipeSpacing.s3) {
                SectionLabel(title: L10n.Home.sectionOnTrend, action: L10n.Home.markets)
                    .padding(.horizontal, RipeSpacing.s5)
                if store.trendItems.isEmpty {
                    trendTracksEmptyView
                } else {
                    trendTracksScrollRail
                }
            }
        }
    }

    private var trendTracksEmptyView: some View {
        SectionEmpty(
            systemImage: "sparkles",
            text: L10n.Home.emptyOnTrend,
            height: RipeSectionEmpty.trendHeight
        )
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var trendTracksScrollRail: some View {
        WithPerceptionTracking {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: RipeSpacing.s4) {
                    ForEach(store.trendItems) { item in
                        trendItemCell(item)
                    }
                }
                .padding(.horizontal, RipeSpacing.s5)
            }
        }
    }

    private func trendItemCell(_ item: HomeFeature.TrendItem) -> some View {
        VStack(alignment: .center, spacing: 7) {
            trendThumbnailWithBadge(item)
            Text(item.name)
                .customFont(.medium12)
                .foregroundStyle(Color(.ripeInk2))
                .lineLimit(1)
                .frame(width: 58)
            DeltaBadge(direction: item.direction, value: item.delta, plain: true)
                .iconFont(size: 11)
        }
        .frame(width: 58)
    }

    private func trendThumbnailWithBadge(_ item: HomeFeature.TrendItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            MonoThumbnail(
                label: item.name,
                categoryColor: item.color,
                size: 58,
                round: true
            )
            directionBadgeOverlay(item.direction)
        }
    }

    private func directionBadgeOverlay(_ direction: PriceDirection) -> some View {
        ZStack {
            Circle()
                .fill(Color(.ripeSurface))
                .frame(width: 18, height: 18)
            DeltaBadge(direction: direction, value: "", plain: true)
                .iconFont(size: 8)
                .offset(x: direction == .up ? 0 : 0)
        }
        .frame(width: 18, height: 18)
        .offset(x: 2, y: 2)
    }

    // MARK: 3 — Expire Soon

    private var expireSoonSection: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: RipeSpacing.s3) {
                SectionLabel(title: L10n.Home.sectionExpireSoon, action: L10n.Home.seeAll)
                    .padding(.horizontal, RipeSpacing.s5)
                if store.expireItems.isEmpty {
                    expireSoonEmptyView
                } else {
                    expireSoonList
                }
            }
        }
    }

    private var expireSoonEmptyView: some View {
        SectionEmpty(
            systemImage: "clock",
            text: L10n.Home.emptyExpireSoon
        )
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var expireSoonList: some View {
        WithPerceptionTracking {
            VStack(spacing: 12) {
                ForEach(store.expireItems) { item in
                    expireItemCard(item)
                }
            }
            .padding(.horizontal, RipeSpacing.s5)
        }
    }

    private func expireItemCard(_ item: HomeFeature.ExpireItem) -> some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                MonoThumbnail(
                    label: item.name,
                    categoryColor: item.color,
                    size: 48
                )
                expireItemTextStack(item)
                Spacer()
                RipeChip(label: item.chipLabel, tone: .warn, systemImage: "clock")
            }
        }
    }

    private func expireItemTextStack(_ item: HomeFeature.ExpireItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.name)
                .customFont(.bold17)
                .foregroundStyle(Color(.ripeInk))
            Text(item.meta)
                .customFont(.medium12)
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    // MARK: 4 — Price Reach Targets

    private var priceTargetsSection: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: RipeSpacing.s3) {
                SectionLabel(
                    title: L10n.Home.sectionPriceTargets,
                    action: L10n.Home.priceTargetHits(store.priceTargetHitCount)
                )
                .padding(.horizontal, RipeSpacing.s5)
                if store.priceTargets.isEmpty {
                    priceTargetsEmptyView
                } else {
                    priceTargetsList
                }
            }
        }
    }

    private var priceTargetsEmptyView: some View {
        SectionEmpty(
            systemImage: "tag",
            text: L10n.Home.emptyPriceTargets
        )
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var priceTargetsList: some View {
        WithPerceptionTracking {
            VStack(spacing: 12) {
                ForEach(store.priceTargets) { target in
                    priceTargetCard(target)
                }
            }
            .padding(.horizontal, RipeSpacing.s5)
        }
    }

    private func priceTargetCard(_ target: HomeFeature.PriceTarget) -> some View {
        RipeCard(padding: 0) {
            VStack(spacing: 0) {
                priceTargetTopArea(target)
                priceTargetDivider
                priceTargetFooterRow(target)
            }
            .background(
                RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
                    .fill(Color(.ripeSurfaceTint))
            )
        }
    }

    private func priceTargetTopArea(_ target: HomeFeature.PriceTarget) -> some View {
        HStack(alignment: .top, spacing: RipeSpacing.s3) {
            MonoThumbnail(
                label: target.name,
                categoryColor: Color(.ripeGood),
                size: 56,
                systemImage: "basket"
            )
            priceTargetDetailStack(target)
        }
        .padding(18)
    }

    private func priceTargetDetailStack(_ target: HomeFeature.PriceTarget) -> some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            priceTargetNameRow(target)
            priceTargetStoreRow(target)
            priceTargetPriceRow(target)
        }
    }

    private func priceTargetNameRow(_ target: HomeFeature.PriceTarget) -> some View {
        HStack(spacing: RipeSpacing.s2) {
            Text(target.name)
                .customFont(.bold17)
                .foregroundStyle(Color(.ripeInk))
            RipeChip(label: "target hit", tone: .good, systemImage: "checkmark")
        }
    }

    private func priceTargetStoreRow(_ target: HomeFeature.PriceTarget) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bag")
                .iconFont(.caption)
                .foregroundStyle(Color(.ripeInk2))
            Text(target.store)
                .customFont(.medium12)
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    private func priceTargetPriceRow(_ target: HomeFeature.PriceTarget) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s2) {
            Text(target.currentPrice)
                .customFont(.bold22)
                .monospacedDigit()
                .foregroundStyle(Color(.ripeGood))
            Text(target.previousPrice)
                .customFont(.bold17)
                .monospacedDigit()
                .foregroundStyle(Color(.ripeInk3))
                .strikethrough(true, color: Color(.ripeInk3))
            DeltaBadge(direction: .down, value: target.deltaValue)
        }
    }

    private var priceTargetDivider: some View {
        Divider()
            .overlay(Color(.ripeLine))
    }

    private func priceTargetFooterRow(_ target: HomeFeature.PriceTarget) -> some View {
        HStack {
            Text(target.targetLabel)
                .customFont(.medium13)
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            RipeButton(
                title: L10n.Home.shopNow,
                variant: .primary,
                size: .sm,
                trailingSystemImage: "chevron.right",
                action: {}
            )
        }
        .padding(.horizontal, RipeSpacing.s4)
        .padding(.vertical, RipeSpacing.s3)
    }
}

// MARK: - Helpers

extension HomeView {
    private var userInitials: String {
        let words = store.userName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
        return words.isEmpty ? "?" : words.joined()
    }
}

// MARK: - Preview

#Preview("Home Empty") {
    HomeView(store: Store(initialState: HomeFeature.State()) { HomeFeature() })
}

#Preview("Home Filled") {
    HomeView(store: Store(initialState: .sample) { HomeFeature() })
}
