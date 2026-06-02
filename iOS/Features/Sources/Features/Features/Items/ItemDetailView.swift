import ComposableArchitecture
import SwiftUI

public struct ItemDetailView: View {
    @Perception.Bindable var store: StoreOf<ItemDetailFeature>

    public init(store: StoreOf<ItemDetailFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    Color(.ripeBg).ignoresSafeArea()
                    scrollContentView
                }
                .navigationTitle(store.item.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        doneButton
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

extension ItemDetailView {

    private var scrollContentView: some View {
        ScrollView {
            VStack(spacing: RipeSpacing.s4) {
                headerCard
                countdownSection
                freshnessBarCard
                statsGridCard
                reminderRowCard
                dangerButtonsView
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s4)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    // MARK: Header card

    private var headerCard: some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                headerMonogram
                headerInfoStack
                Spacer()
            }
        }
    }

    private var headerMonogram: some View {
        MonoThumbnail(
            label: store.item.name,
            categoryColor: freshnessAccentColor,
            size: 56
        )
    }

    private var headerInfoStack: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(store.item.name)
                .font(RipeFont.heading(17))
                .foregroundStyle(Color(.ripeInk))
            headerSubtitleText
        }
    }

    private var headerSubtitleText: some View {
        let parts = [store.item.quantity, store.item.locationLabel].compactMap { $0 }
        return Text(parts.joined(separator: " \u{00B7} "))
            .font(RipeFont.caption(13))
            .foregroundStyle(Color(.ripeInk2))
    }

    // MARK: Countdown section

    private var countdownSection: some View {
        RipeCard {
            VStack(spacing: RipeSpacing.s3) {
                sectionLabel("COUNTDOWN")
                countdownReadout
            }
        }
    }

    private var countdownReadout: some View {
        HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s2) {
            Text("\(abs(store.item.daysLeft))")
                .font(RipeFont.display(64))
                .foregroundStyle(Color(.ripeInk))
                .monospacedDigit()
            Text("days")
                .font(RipeFont.body(20))
                .foregroundStyle(Color(.ripeInk2))
                .padding(.bottom, 6)
            Spacer()
            freshnessChip
        }
    }

    private var freshnessChip: some View {
        switch store.item.freshness {
        case .fresh:
            return RipeChip(label: "Fresh", tone: .good, systemImage: "leaf")
        case .expiring:
            return RipeChip(label: "Expiring", tone: .warn, systemImage: "clock")
        case .expired:
            return RipeChip(label: "Expired", tone: .danger, systemImage: "xmark.circle")
        }
    }

    // MARK: Freshness bar card

    private var freshnessBarCard: some View {
        RipeCard {
            VStack(spacing: RipeSpacing.s3) {
                sectionLabel("FRESHNESS")
                freshnessBarView
                freshnessBarLabels
            }
        }
    }

    private var freshnessBarView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                freshnessGradientBar
                todayMarkerKnob
                    .offset(x: markerOffset(in: geo.size.width))
            }
        }
        .frame(height: 12)
    }

    private var freshnessGradientBar: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(.ripeGood), Color(.ripeWarn), Color(.ripeDanger)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private var todayMarkerKnob: some View {
        Circle()
            .fill(Color(.ripeSurface))
            .frame(width: 18, height: 18)
            .overlay(
                Circle().strokeBorder(Color(.ripeInk2), lineWidth: 2)
            )
            .shadow(color: Color(.ripeInk).opacity(0.15), radius: 3, y: 2)
    }

    private var freshnessBarLabels: some View {
        HStack {
            Text(shortDate(store.item.addedDate))
                .font(RipeFont.caption(11))
                .foregroundStyle(Color(.ripeInk3))
            Spacer()
            Text(shortDate(store.item.bestBeforeDate))
                .font(RipeFont.caption(11))
                .foregroundStyle(Color(.ripeInk3))
        }
    }

    // MARK: Stats grid card

    private var statsGridCard: some View {
        RipeCard {
            VStack(spacing: RipeSpacing.s3) {
                sectionLabel("DETAILS")
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: RipeSpacing.s4
                ) {
                    statCell(title: "Best before", value: shortDate(store.item.bestBeforeDate))
                    statCell(title: "Added", value: shortDate(store.item.addedDate))
                    statCell(title: "Reminder", value: shortDate(store.item.remindOn))
                    statCell(title: "Location", value: store.item.locationLabel)
                }
            }
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(title)
                .font(RipeFont.caption(11))
                .foregroundStyle(Color(.ripeInk3))
                .textCase(.uppercase)
                .tracking(0.3)
            Text(value)
                .font(RipeFont.body(14))
                .foregroundStyle(Color(.ripeInk))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Reminder row card

    private var reminderRowCard: some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(.ripeAccent))
                VStack(alignment: .leading, spacing: RipeSpacing.s1) {
                    Text("Reminder")
                        .font(RipeFont.body(15))
                        .foregroundStyle(Color(.ripeInk))
                    Text(shortDate(store.item.remindOn))
                        .font(RipeFont.caption(13))
                        .foregroundStyle(Color(.ripeInk2))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.ripeInk3))
            }
        }
        .onTapGesture { store.send(.editReminderTapped) }
    }

    // MARK: Action buttons

    private var dangerButtonsView: some View {
        VStack(spacing: RipeSpacing.s3) {
            markUsedButton
            deleteButton
        }
    }

    private var markUsedButton: some View {
        RipeButton(
            title: store.isMarkingUsed ? "Marking\u{2026}" : "Mark as used",
            variant: .secondary,
            size: .lg,
            systemImage: "checkmark.circle",
            fullWidth: true,
            action: { store.send(.markUsedButtonTapped) }
        )
        .disabled(store.isMarkingUsed || store.isDeleting)
    }

    private var deleteButton: some View {
        Button {
            store.send(.deleteButtonTapped)
        } label: {
            deleteButtonLabel
        }
        .buttonStyle(.plain)
        .disabled(store.isDeleting || store.isMarkingUsed)
    }

    private var deleteButtonLabel: some View {
        HStack(spacing: RipeSpacing.s2) {
            if store.isDeleting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(.ripeDanger)))
                    .scaleEffect(0.85)
            } else {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(store.isDeleting ? "Deleting\u{2026}" : "Delete item")
                .font(RipeFont.label(15))
                .fontWeight(.semibold)
        }
        .foregroundStyle(Color(.ripeDanger))
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Color(.ripeDangerSoft))
        .clipShape(Capsule())
    }

    // MARK: Toolbar

    private var doneButton: some View {
        Button("Done") {
            store.send(.deleteConfirmed)
        }
    }
}

// MARK: - Helpers

extension ItemDetailView {

    private var freshnessAccentColor: Color {
        switch store.item.freshness {
        case .fresh:    return Color(.ripeGood)
        case .expiring: return Color(.ripeWarn)
        case .expired:  return Color(.ripeDanger)
        }
    }

    private func markerOffset(in totalWidth: CGFloat) -> CGFloat {
        let knobWidth: CGFloat = 18
        let totalDays = Calendar.current.dateComponents(
            [.day], from: store.item.addedDate, to: store.item.bestBeforeDate
        ).day ?? 1
        let daysSinceAdded = Calendar.current.dateComponents(
            [.day], from: store.item.addedDate, to: Date()
        ).day ?? 0
        let frac = max(0, min(1, Double(daysSinceAdded) / Double(max(totalDays, 1))))
        return (totalWidth - knobWidth) * frac
    }

    private func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(RipeFont.caption(11))
            .foregroundStyle(Color(.ripeInk3))
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    let item = Item(
        id: UUID(),
        name: "Greek Yogurt",
        quantity: "2 cups",
        location: .fridge,
        bestBeforeDate: Date().addingTimeInterval(5 * 86400),
        addedDate: Date().addingTimeInterval(-2 * 86400),
        remindDaysBefore: 3
    )
    ItemDetailView(store: Store(initialState: ItemDetailFeature.State(item: item)) {
        ItemDetailFeature()
    })
}
