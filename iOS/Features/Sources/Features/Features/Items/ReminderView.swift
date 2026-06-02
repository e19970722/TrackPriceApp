import ComposableArchitecture
import SwiftUI

public struct ReminderView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>
    let draftItem: Item

    public init(store: StoreOf<AddItemFeature>, draftItem: Item) {
        self.store = store
        self.draftItem = draftItem
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg).ignoresSafeArea()
                scrollContent
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews

extension ReminderView {

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: RipeSpacing.s5) {
                itemSummaryCard
                reminderDaysCard
                reminderBannerView
                alsoAlertOnDayRow
                saveButton
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s5)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    // MARK: Item summary card

    private var itemSummaryCard: some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                itemMonogram
                itemSummaryTextStack
                Spacer()
                daysLeftChip
            }
        }
    }

    private var itemMonogram: some View {
        MonoThumbnail(
            label: draftItem.name,
            categoryColor: Color(.ripeAccent),
            size: 50
        )
    }

    private var itemSummaryTextStack: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(draftItem.name)
                .font(RipeFont.heading(16))
                .foregroundStyle(Color(.ripeInk))
                .lineLimit(1)
            Text("Best before \(shortDate(draftItem.bestBeforeDate))")
                .font(RipeFont.caption(13))
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    private var daysLeftChip: some View {
        let days = draftItem.daysLeft
        let tone: ChipTone = days < 0 ? .danger : days <= 3 ? .warn : .good
        return RipeChip(label: "\(days)d left", tone: tone)
    }

    // MARK: Days-before slider card

    private var reminderDaysCard: some View {
        RipeCard {
            VStack(spacing: RipeSpacing.s5) {
                daysReadoutView
                discreteSliderView
                sliderTickLabels
            }
        }
    }

    private var daysReadoutView: some View {
        HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s1) {
            Text("\(store.remindDaysBefore)")
                .font(RipeFont.display(60))
                .foregroundStyle(Color(.ripeInk))
            Text("days before")
                .font(RipeFont.body(18))
                .foregroundStyle(Color(.ripeInk2))
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var discreteSliderView: some View {
        DiscreteSlider(
            stops: reminderStops,
            selected: store.remindDaysBefore,
            onChanged: { store.send(.remindDaysBeforeChanged($0)) }
        )
    }

    private var sliderTickLabels: some View {
        HStack {
            ForEach(reminderStops, id: \.self) { stop in
                Text("\(stop)")
                    .font(RipeFont.caption(11))
                    .foregroundStyle(stop == store.remindDaysBefore ? Color(.ripeAccent) : Color(.ripeInk3))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Banner

    private var reminderBannerView: some View {
        HStack(spacing: RipeSpacing.s3) {
            Image(systemName: "bell.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(.ripeAccent))
            Text(reminderBannerText)
                .font(RipeFont.body(14))
                .foregroundStyle(Color(.ripeInk))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RipeSpacing.s4)
        .background(Color(.ripeAccentSoft))
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous))
    }

    // MARK: Also-alert-on-day toggle

    private var alsoAlertOnDayRow: some View {
        RipeCard {
            HStack {
                VStack(alignment: .leading, spacing: RipeSpacing.s1) {
                    Text("Also alert on the day")
                        .font(RipeFont.body(15))
                        .foregroundStyle(Color(.ripeInk))
                    Text("Morning of \(shortDate(draftItem.bestBeforeDate))")
                        .font(RipeFont.caption(13))
                        .foregroundStyle(Color(.ripeInk2))
                }
                Spacer()
                Toggle("", isOn: $store.remindOnDay)
                    .labelsHidden()
                    .tint(Color(.ripeAccent))
            }
        }
    }

    // MARK: Save button

    private var saveButton: some View {
        RipeButton(
            title: store.isSaving ? "Saving\u{2026}" : "Save item",
            variant: .primary,
            size: .lg,
            fullWidth: true,
            action: { store.send(.saveItemTapped) }
        )
        .disabled(store.isSaving)
    }
}

// MARK: - Helpers

extension ReminderView {

    private var reminderStops: [Int] { [1, 3, 7, 30, 60] }

    private var reminderBannerText: String {
        let onDate = shortDate(draftItem.remindOn)
        let days = store.remindDaysBefore
        return "We'll remind you on \(onDate) — \(days) day\(days == 1 ? "" : "s") before it expires."
    }

    private func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

// MARK: - DiscreteSlider

private struct DiscreteSlider: View {
    let stops: [Int]
    let selected: Int
    let onChanged: (Int) -> Void

    private var normalised: Double {
        guard let idx = stops.firstIndex(of: selected) else { return 0 }
        return Double(idx) / Double(stops.count - 1)
    }

    var body: some View {
        Slider(
            value: Binding(
                get: { normalised },
                set: { raw in
                    let idx = Int((raw * Double(stops.count - 1)).rounded())
                    onChanged(stops[max(0, min(idx, stops.count - 1))])
                }
            )
        )
        .tint(Color(.ripeAccent))
    }
}

// MARK: - Preview

#Preview {
    let draft = Item(
        name: "Greek Yogurt",
        quantity: "2 cups",
        location: .fridge,
        bestBeforeDate: Date().addingTimeInterval(7 * 86400)
    )
    NavigationStack {
        ReminderView(
            store: Store(initialState: AddItemFeature.State()) { AddItemFeature() },
            draftItem: draft
        )
    }
}
