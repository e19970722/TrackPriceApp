import Charts
import ComposableArchitecture
import SwiftUI

public struct TrackerDetailView: View {
    @Perception.Bindable var store: StoreOf<TrackerDetailFeature>
    @Environment(\.openURL) private var openURL

    public init(store: StoreOf<TrackerDetailFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCardView
                        priceChartSection
                        detailStatsSection
                        shopNowButton
                    }
                    .padding()
                }
                .navigationTitle(store.tracker.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        dismissButton
                    }
                }
            }
            .onAppear { store.send(.onAppear) }
        }
    }
}

// MARK: - Subviews

extension TrackerDetailView {
    private var dismissButton: some View {
        Button(L10n.Common.done) {
            store.send(.dismiss)
        }
    }

    private var headerCardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerHeroImageView
            itemNameLabel
            priceRowView
            targetRowView
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var headerHeroImageView: some View {
        if let imageUrl = store.tracker.itemImageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var itemNameLabel: some View {
        if let itemName = store.tracker.itemName {
            Text(itemName)
                .customFont(.medium15)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var priceRowView: some View {
        HStack(alignment: .firstTextBaseline) {
            currentPriceLabel
            Spacer()
            StatusBadge(status: store.tracker.status)
        }
    }

    private var currentPriceLabel: some View {
        Group {
            if let lastPrice = store.tracker.lastPrice {
                Text("\(store.tracker.currencySymbol)\(String(format: "%.2f", lastPrice))")
            } else {
                Text(L10n.TrackerDetail.noData)
                    .foregroundStyle(.secondary)
            }
        }
        .customFont(.extrabold40)
    }

    private var targetRowView: some View {
        HStack(spacing: 8) {
            DirectionBadge(direction: store.tracker.targetDirection)
            Text(L10n.TrackerDetail.targetPrice(
                "\(store.tracker.currencySymbol)\(String(format: "%.2f", store.tracker.targetPrice))"
            ))
            .customFont(.medium15)
            .foregroundStyle(.secondary)
        }
    }

    private var priceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.TrackerDetail.priceHistory)
                .customFont(.bold17)

            chartContentView
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var chartContentView: some View {
        if store.isLoadingHistory {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if store.history.isEmpty {
            emptyChartView
        } else {
            priceLineChart
        }
    }

    private var emptyChartView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .iconFont(.heroPlain)
                .foregroundStyle(.secondary)
            Text(L10n.TrackerDetail.noPriceHistory)
                .customFont(.medium15)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    @ViewBuilder
    private var priceLineChart: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(store.history) { snapshot in
                    LineMark(
                        x: .value("Date", snapshot.scrapedAt),
                        y: .value("Price", snapshot.price)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", snapshot.scrapedAt),
                        y: .value("Price", snapshot.price)
                    )
                    .foregroundStyle(Color.accentColor.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }

                RuleMark(y: .value("Target", store.tracker.targetPrice))
                    .foregroundStyle(.red.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .trailing, alignment: .center) {
                        Text(L10n.TrackerDetail.target)
                            .customFont(.medium10)
                            .foregroundStyle(.red.opacity(0.7))
                    }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text("\(store.tracker.currencySymbol)\(String(format: "%.0f", price))")
                                .customFont(.medium10)
                        }
                    }
                }
            }
        }
    }

    private var shopNowButton: some View {
        Button {
            if let url = URL(string: store.tracker.url) {
                openURL(url)
            }
        } label: {
            Text(L10n.TrackerDetail.shopNow)
                .customFont(.bold17)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var detailStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.TrackerDetail.details)
                .customFont(.bold17)

            statsGridView
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCell(title: L10n.TrackerDetail.statUrl, value: store.tracker.url, truncate: true)
            StatCell(title: L10n.TrackerDetail.statCreated, value: formattedDate(store.tracker.createdAt))
            if let lastChecked = store.tracker.lastCheckedAt {
                StatCell(title: L10n.TrackerDetail.statLastChecked, value: formattedDate(lastChecked))
            } else {
                StatCell(title: L10n.TrackerDetail.statLastChecked, value: L10n.TrackerDetail.lastCheckedNever)
            }
            StatCell(title: L10n.TrackerDetail.statNextCheck, value: nextCheckLabel(store.tracker.nextCheckedAt))
        }
    }
}

// MARK: - Helpers

extension TrackerDetailView {
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func nextCheckLabel(_ date: Date?) -> String {
        guard let date, date > Date() else { return "Scheduled soon" }
        let hours = Int(date.timeIntervalSinceNow / 3600)
        let minutes = Int((date.timeIntervalSinceNow.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "in ~\(hours)h \(minutes)m" }
        return "in ~\(max(minutes, 1))m"
    }
}

// MARK: - Preview

#Preview {
    let tracker = Tracker(
        id: UUID(),
        name: "MacBook Pro 14\"",
        url: "https://www.apple.com/shop/buy-mac/macbook-pro",
        currencySymbol: "$",
        targetPrice: 1800.00,
        targetDirection: .below,
        status: .active,
        lastPrice: 1999.00,
        lastCheckedAt: Date(),
        checkInterval: 180,
        nextCheckedAt: Date().addingTimeInterval(7200),
        createdAt: Date()
    )
    TrackerDetailView(store: Store(
        initialState: TrackerDetailFeature.State(tracker: tracker)
    ) {
        TrackerDetailFeature()
    })
}
