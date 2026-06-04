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
        HStack(alignment: .center) {
            greetingTextStack
            Spacer()
            avatarThumbnailView
        }
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var greetingTextStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.Home.greeting)
                .font(RipeFont.label(14))
                .foregroundStyle(Color(.ripeInk2))
            Text(store.userName)
                .font(RipeFont.display(30))
                .foregroundStyle(Color(.ripeInk))
        }
    }

    private var avatarThumbnailView: some View {
        MonoThumbnail(
            label: "SR",
            categoryColor: Color(.ripeAccent),
            size: 46,
            round: true
        )
    }

    // MARK: 2 — On Trend Tracks

    private var trendTracksSection: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            SectionLabel(title: L10n.Home.sectionOnTrend, action: L10n.Home.markets)
                .padding(.horizontal, RipeSpacing.s5)
            trendTracksScrollRail
        }
    }

    private var trendTracksScrollRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: RipeSpacing.s4) {
                ForEach(trendItems) { item in
                    trendItemCell(item)
                }
            }
            .padding(.horizontal, RipeSpacing.s5)
        }
    }

    private func trendItemCell(_ item: TrendItem) -> some View {
        VStack(alignment: .center, spacing: 7) {
            trendThumbnailWithBadge(item)
            Text(item.name)
                .font(RipeFont.caption(11.5))
                .foregroundStyle(Color(.ripeInk2))
                .lineLimit(1)
                .frame(width: 58)
            DeltaBadge(direction: item.direction, value: item.delta, plain: true)
                .font(.system(size: 11))
        }
        .frame(width: 58)
    }

    private func trendThumbnailWithBadge(_ item: TrendItem) -> some View {
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
                .font(.system(size: 8))
                .offset(x: direction == .up ? 0 : 0)
        }
        .frame(width: 18, height: 18)
        .offset(x: 2, y: 2)
    }

    // MARK: 3 — Expire Soon

    private var expireSoonSection: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            SectionLabel(title: L10n.Home.sectionExpireSoon, action: L10n.Home.seeAll)
                .padding(.horizontal, RipeSpacing.s5)
            VStack(spacing: 12) {
                ForEach(expireItems) { item in
                    expireItemCard(item)
                }
            }
            .padding(.horizontal, RipeSpacing.s5)
        }
    }

    private func expireItemCard(_ item: ExpireItem) -> some View {
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

    private func expireItemTextStack(_ item: ExpireItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.name)
                .font(RipeFont.heading(15))
                .foregroundStyle(Color(.ripeInk))
            Text(item.meta)
                .font(RipeFont.caption(12))
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    // MARK: 4 — Price Reach Targets

    private var priceTargetsSection: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            SectionLabel(title: L10n.Home.sectionPriceTargets, action: "3 hits")
                .padding(.horizontal, RipeSpacing.s5)
            priceTargetCard
                .padding(.horizontal, RipeSpacing.s5)
        }
    }

    private var priceTargetCard: some View {
        RipeCard(padding: 0) {
            VStack(spacing: 0) {
                priceTargetTopArea
                priceTargetDivider
                priceTargetFooterRow
            }
            .background(
                RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
                    .fill(Color(.ripeSurfaceTint))
            )
        }
    }

    private var priceTargetTopArea: some View {
        HStack(alignment: .top, spacing: RipeSpacing.s3) {
            MonoThumbnail(
                label: "Olive Oil",
                categoryColor: Color(.ripeGood),
                size: 56,
                systemImage: "basket"
            )
            priceTargetDetailStack
        }
        .padding(18)
    }

    private var priceTargetDetailStack: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            priceTargetNameRow
            priceTargetStoreRow
            priceTargetPriceRow
        }
    }

    private var priceTargetNameRow: some View {
        HStack(spacing: RipeSpacing.s2) {
            Text("Olive Oil")
                .font(RipeFont.heading(16))
                .foregroundStyle(Color(.ripeInk))
            RipeChip(label: "target hit", tone: .good, systemImage: "checkmark")
        }
    }

    private var priceTargetStoreRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "bag")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(.ripeInk2))
            Text("Trader Joe's · 500 ml")
                .font(RipeFont.caption(12))
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    private var priceTargetPriceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s2) {
            Text("$8.99")
                .font(RipeFont.num(28))
                .foregroundStyle(Color(.ripeGood))
            Text("$10.10")
                .font(RipeFont.num(15))
                .foregroundStyle(Color(.ripeInk3))
                .strikethrough(true, color: Color(.ripeInk3))
            DeltaBadge(direction: .down, value: "11%")
        }
    }

    private var priceTargetDivider: some View {
        Divider()
            .overlay(Color(.ripeLine))
    }

    private var priceTargetFooterRow: some View {
        HStack {
            Text("Target was $9.00")
                .font(RipeFont.caption(13))
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
    private struct TrendItem: Identifiable {
        let id = UUID()
        let name: String
        let direction: PriceDirection
        let delta: String
        let color: Color
    }

    private var trendItems: [TrendItem] {
        let colors: [Color] = [
            Color(.ripeCat1),
            Color(.ripeCat2),
            Color(.ripeCat3),
            Color(.ripeCat4),
            Color(.ripeCat5),
        ]
        return [
            TrendItem(name: "Coffee", direction: .up, delta: "6%", color: colors[0]),
            TrendItem(name: "Olive Oil", direction: .down, delta: "11%", color: colors[1]),
            TrendItem(name: "Eggs", direction: .up, delta: "4%", color: colors[2]),
            TrendItem(name: "Butter", direction: .down, delta: "8%", color: colors[3]),
            TrendItem(name: "Detergent", direction: .down, delta: "12%", color: colors[4]),
        ]
    }

    private struct ExpireItem: Identifiable {
        let id = UUID()
        let name: String
        let meta: String
        let chipLabel: String
        let color: Color
    }

    private var expireItems: [ExpireItem] {
        [
            ExpireItem(name: "Greek Yogurt", meta: "2 cups · Fridge", chipLabel: "2d left", color: Color(.ripeCat3)),
            ExpireItem(name: "Eggs", meta: "6 left · Fridge", chipLabel: "3d left", color: Color(.ripeCat2)),
        ]
    }
}

// MARK: - Preview

#Preview {
    HomeView(store: Store(initialState: HomeFeature.State()) { HomeFeature() })
}
