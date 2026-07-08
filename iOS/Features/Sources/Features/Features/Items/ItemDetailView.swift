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
                    Color(.ripeBg)
                        .ignoresSafeArea()
                    scrollContentView
                }
                .navigationTitle(store.item.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.Common.close) { store.send(.closeButtonTapped) }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Common.edit) { store.send(.editButtonTapped) }
                    }
                }
                .sheet(item: $store.scope(state: \.editItem, action: \.editItem)) { editStore in
                    editItemSheet(store: editStore)
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

    // MARK: Edit sheet

    /// Reuses the add-flow item-details form (in edit mode) to edit this item.
    private func editItemSheet(store editStore: StoreOf<AddExpiryTrackerFeature>) -> some View {
        NavigationStack {
            ItemDetailsView(store: editStore)
        }
    }

    // MARK: Header card

    private var headerCard: some View {
        HStack(spacing: RipeSpacing.s3) {
            headerMonogram
            headerInfoStack
            Spacer()
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
                .customFont(.bold17)
                .foregroundStyle(Color(.ripeInk))
            headerSubtitleText
        }
    }

    private var headerSubtitleText: some View {
        let parts = [store.item.quantity, store.item.locationLabel].compactMap { $0 }
        return Text(parts.joined(separator: " \u{00B7} "))
            .customFont(.medium13)
            .foregroundStyle(Color(.ripeInk2))
    }

    // MARK: Countdown section

    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            sectionLabel(L10n.Expiry.sectionUntilBestBefore)
            countdownReadout
        }
    }

    private var countdownReadout: some View {
        HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s2) {
            Text("\(abs(store.item.daysLeft))")
                .customFont(.extrabold40)
                .foregroundStyle(Color(.ripeInk))
                .monospacedDigit()
            Text(L10n.Expiry.days)
                .customFont(.semibold18)
                .foregroundStyle(Color(.ripeInk2))
                .padding(.bottom, 4)
            freshnessChip
            Spacer()
        }
    }

    private var freshnessChip: some View {
        switch store.item.freshness {
        case .fresh:
            RipeChip(label: "Fresh", tone: .good, systemImage: "leaf")
        case .expiring:
            RipeChip(label: "Expiring", tone: .warn, systemImage: "clock")
        case .expired:
            RipeChip(label: "Expired", tone: .danger, systemImage: "xmark.circle")
        }
    }

    // MARK: Freshness bar card

    private var freshnessBarCard: some View {
        RipeCard {
            VStack(spacing: RipeSpacing.s3) {
                sectionLabel(L10n.Expiry.sectionFreshness)
                freshnessBarView
                freshnessBarLabels
            }
        }
    }

    private var freshnessBarView: some View {
        GeometryReader { geo in
            // `GeometryReader` evaluates its content outside the `body` tracking
            // scope, and `markerOffset(in:)` reads `store.item`.
            WithPerceptionTracking {
                ZStack(alignment: .leading) {
                    freshnessGradientBar
                    todayMarkerKnob
                        .offset(x: markerOffset(in: geo.size.width))
                }
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
                .customFont(.medium11)
                .foregroundStyle(Color(.ripeInk3))
            Spacer()
            Text(shortDate(store.item.bestBeforeDate))
                .customFont(.medium11)
                .foregroundStyle(Color(.ripeInk3))
        }
    }

    // MARK: Stats grid card

    private var statsGridCard: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: RipeSpacing.s3
        ) {
            // `LazyVGrid` evaluates its content lazily, outside the `body` tracking
            // scope, so the store reads below need their own `WithPerceptionTracking`.
            WithPerceptionTracking {
                statCard(
                    icon: "calendar",
                    title: L10n.Expiry.statBestBefore,
                    value: shortDate(store.item.bestBeforeDate)
                )
                statCard(
                    icon: "leaf",
                    title: L10n.Expiry.statAdded,
                    value: shortDate(store.item.addedDate)
                )
                statCard(
                    icon: "bell",
                    title: L10n.Expiry.statReminderTitle,
                    value: L10n.Expiry.reminderDaysBefore(store.item.remindDaysBefore)
                )
                statCard(
                    icon: "refrigerator",
                    title: L10n.Expiry.statLocation,
                    value: store.item.locationLabel ?? ""
                )
            }
        }
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        RipeCard {
            VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                Image(systemName: icon)
                    .iconFont(.md)
                    .foregroundStyle(Color(.ripeAccent))
                Text(title)
                    .customFont(.medium11)
                    .foregroundStyle(Color(.ripeInk3))
                    .textCase(.uppercase)
                    .tracking(0.3)
                Text(value)
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Reminder row card

    private var reminderRowCard: some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                Image(systemName: "bell.fill")
                    .iconFont(.sectionIcon)
                    .foregroundStyle(Color(.ripeAccent))
                VStack(alignment: .leading, spacing: RipeSpacing.s1) {
                    Text(L10n.Expiry.reminderSection)
                        .customFont(.semibold15)
                        .foregroundStyle(Color(.ripeInk))
                    Text(shortDate(store.item.remindOn))
                        .customFont(.medium13)
                        .foregroundStyle(Color(.ripeInk2))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .iconFont(.sm)
                    .foregroundStyle(Color(.ripeInk3))
            }
        }
        .onTapGesture { store.send(.editReminderTapped) }
    }

    // MARK: Action buttons

    private var dangerButtonsView: some View {
        HStack(spacing: RipeSpacing.s3) {
            deleteButton
            markUsedButton
        }
    }

    private var markUsedButton: some View {
        RipeButton(
            title: store.isMarkingUsed ? L10n.Expiry.markingUsed : L10n.Expiry.markUsed,
            variant: .primary,
            size: .lg,
            systemImage: "checkmark",
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
                    .iconFont(.md)
            }
            Text(store.isDeleting ? "Deleting\u{2026}" : "Delete item")
                .customFont(.semibold15)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Color(.ripeDanger))
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Color(.ripeDangerSoft))
        .clipShape(Capsule())
    }
}

// MARK: - Helpers

extension ItemDetailView {
    private var freshnessAccentColor: Color {
        switch store.item.freshness {
        case .fresh: Color(.ripeGood)
        case .expiring: Color(.ripeWarn)
        case .expired: Color(.ripeDanger)
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
            .customFont(.medium11)
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
