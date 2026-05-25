import Charts
import ComposableArchitecture
import SwiftUI

public struct TrackerDetailView: View {
    @Perception.Bindable var store: StoreOf<TrackerDetailFeature>

    public init(store: StoreOf<TrackerDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard
                        chartSection
                        statsGrid
                    }
                    .padding()
                }
                .navigationTitle(store.tracker.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            store.send(.dismiss)
                        }
                    }
                }
            }
            .onAppear { store.send(.onAppear) }
        }
    }

    // MARK: - Header card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                if let lastPrice = store.tracker.lastPrice {
                    Text("\(store.tracker.currencySymbol)\(String(format: "%.2f", lastPrice))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                } else {
                    Text("—")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge
            }

            HStack(spacing: 8) {
                directionBadge
                Text("Target: \(store.tracker.currencySymbol)\(String(format: "%.2f", store.tracker.targetPrice))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var directionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: store.tracker.targetDirection == .below ? "arrow.down" : "arrow.up")
            Text(store.tracker.targetDirection == .below ? "Below" : "Above")
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            store.tracker.targetDirection == .below ? Color.green.opacity(0.15) : Color.orange.opacity(0.15),
            in: Capsule()
        )
        .foregroundStyle(store.tracker.targetDirection == .below ? .green : .orange)
    }

    private var statusBadge: some View {
        let (color, label): (Color, String) = {
            switch store.tracker.status {
            case .active:  return (.green, "Active")
            case .paused:  return (.orange, "Paused")
            case .broken:  return (.red, "Broken")
            }
        }()
        return Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    // MARK: - Chart section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price History")
                .font(.headline)

            if store.isLoadingHistory {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if store.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No price history yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
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
                                Text("Target")
                                    .font(.caption2)
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
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCell(title: "URL", value: store.tracker.url, truncate: true)
                statCell(title: "Created", value: formattedDate(store.tracker.createdAt))
                if let lastChecked = store.tracker.lastCheckedAt {
                    statCell(title: "Last Checked", value: formattedDate(lastChecked))
                } else {
                    statCell(title: "Last Checked", value: "Never")
                }
                statCell(title: "Next Check", value: nextCheckLabel(store.tracker.nextCheckAt))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statCell(title: String, value: String, truncate: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
                .lineLimit(truncate ? 2 : nil)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

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
        checkInterval: "3h",
        nextCheckAt: Date().addingTimeInterval(7200),
        createdAt: Date()
    )
    TrackerDetailView(store: Store(
        initialState: TrackerDetailFeature.State(tracker: tracker)
    ) {
        TrackerDetailFeature()
    })
}
