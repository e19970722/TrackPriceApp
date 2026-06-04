import ComposableArchitecture
import SwiftUI

public struct ReminderView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>
    let draftItem: Item
    private let milestoneMarks: [Int] = [1, 3, 7, 30, 60]

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
            VStack(alignment: .leading, spacing: RipeSpacing.s5) {
                itemSummaryCard
                remindSectionLabel
                daysReadoutView
                sliderSection
                reminderBannerView
                alsoAlertOnDayRow
                saveButton
                backButton
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
            size: 46
        )
    }

    private var itemSummaryTextStack: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(draftItem.name)
                .font(RipeFont.heading(15))
                .foregroundStyle(Color(.ripeInk))
                .lineLimit(1)
            Text("Best before \(shortDate(draftItem.bestBeforeDate))")
                .font(RipeFont.caption(12))
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    private var daysLeftChip: some View {
        let days = draftItem.daysLeft
        let tone: ChipTone = days < 0 ? .danger : days <= 3 ? .warn : .good
        return RipeChip(label: "\(days)d left", tone: tone)
    }

    // MARK: Section label (no card)

    private var remindSectionLabel: some View {
        Text("Remind me before it expires")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(.ripeInk2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
    }

    // MARK: Days readout (no card — accent color per design)

    private var daysReadoutView: some View {
        WithPerceptionTracking {
            HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s2) {
                Text("\(store.remindDaysBefore)")
                    .font(RipeFont.display(44))
                    .foregroundStyle(Color(.ripeAccent))
                    .monospacedDigit()
                Text("days before")
                    .font(RipeFont.body(18))
                    .foregroundStyle(Color(.ripeInk2))
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: Slider + milestone labels (no card)

    private var sliderSection: some View {
        WithPerceptionTracking {
            VStack(spacing: RipeSpacing.s2) {
                Slider(value: sliderBinding, in: 1...60, step: 1)
                    .tint(Color(.ripeAccent))
                sliderMilestoneLabels
            }
        }
    }

    private var sliderMilestoneLabels: some View {
        WithPerceptionTracking {
            HStack {
                ForEach(milestoneMarks, id: \.self) { mark in
                    let isActive = mark == store.remindDaysBefore
                    Group {
                        if mark == milestoneMarks.first {
                            Text("\(mark)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if mark == milestoneMarks.last {
                            Text("\(mark)")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Text("\(mark)")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .font(.system(size: 12, weight: isActive ? .bold : .semibold))
                    .foregroundStyle(isActive ? Color(.ripeAccent) : Color(.ripeInk3))
                    .monospacedDigit()
                }
            }
        }
    }

    // MARK: Banner

    private var reminderBannerView: some View {
        WithPerceptionTracking {
            HStack(spacing: RipeSpacing.s3) {
                Image(systemName: isReminderInPast ? "exclamationmark.triangle.fill" : "bell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isReminderInPast ? Color(.ripeWarn) : Color(.ripeAccent))
                Text(isReminderInPast ? reminderPastHintText : reminderBannerText)
                    .font(RipeFont.body(14))
                    .foregroundStyle(Color(.ripeInk))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(RipeSpacing.s4)
            .background(isReminderInPast ? Color(.ripeWarnSoft) : Color(.ripeAccentSoft))
            .clipShape(RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous))
        }
    }

    // MARK: Also-alert-on-day toggle (with green calendar icon per design)

    private var alsoAlertOnDayRow: some View {
        WithPerceptionTracking {
            RipeCard {
                HStack(spacing: 13) {
                    calendarCheckIcon
                    VStack(alignment: .leading, spacing: RipeSpacing.s1) {
                        Text("Also alert on the day")
                            .font(RipeFont.body(15))
                            .foregroundStyle(Color(.ripeInk))
                        Text("Morning of \(shortDate(draftItem.bestBeforeDate))")
                            .font(RipeFont.caption(12))
                            .foregroundStyle(Color(.ripeInk2))
                    }
                    Spacer()
                    Toggle("", isOn: $store.remindOnDay)
                        .labelsHidden()
                        .tint(Color(.ripeAccent))
                }
            }
        }
    }

    private var calendarCheckIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.ripeGood).opacity(0.1))
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(.ripeGood))
        }
        .frame(width: 36, height: 36)
    }

    // MARK: Save button

    private var saveButton: some View {
        WithPerceptionTracking {
            RipeButton(
                title: store.isSaving ? "Saving\u{2026}" : "Save item",
                variant: .primary,
                size: .lg,
                fullWidth: true,
                action: { store.send(.saveItemTapped) }
            )
            .disabled(store.isSaving || isReminderInPast)
        }
    }

    private var backButton: some View {
        RipeButton(
            title: "Back",
            variant: .outline,
            size: .lg,
            fullWidth: true,
            action: { store.send(.backTapped) }
        )
    }
}

// MARK: - Helpers

extension ReminderView {


    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(store.remindDaysBefore) },
            set: { store.send(.remindDaysBeforeChanged(Int($0.rounded()))) }
        )
    }

    private var computedRemindOn: Date {
        Calendar.current.date(
            byAdding: .day,
            value: -store.remindDaysBefore,
            to: draftItem.bestBeforeDate
        ) ?? draftItem.bestBeforeDate
    }

    private var isReminderInPast: Bool {
        computedRemindOn < Calendar.current.startOfDay(for: .now)
    }

    private var reminderBannerText: String {
        let onDate = shortDate(computedRemindOn)
        let days = store.remindDaysBefore
        return "We'll remind you on \(onDate) — \(days) day\(days == 1 ? "" : "s") before it expires."
    }

    private var reminderPastHintText: String {
        "\(shortDate(computedRemindOn)) has already passed — choose fewer days before expiry."
    }

    private func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
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
