import ComposableArchitecture
import PhotosUI
import SwiftUI

public struct ReminderView: View {
    @Perception.Bindable var store: StoreOf<AddExpiryTrackerFeature>
    let draftItem: Item
    private let milestoneMarks: [Int] = [1, 3, 7, 30, 60]

    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: Image?

    public init(store: StoreOf<AddExpiryTrackerFeature>, draftItem: Item) {
        self.store = store
        self.draftItem = draftItem
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(alignment: .leading, spacing: RipeSpacing.s5) {
                    itemSummaryCard
                    remindSectionLabel
                    daysReadoutView
                    sliderSection
                    reminderBannerView
                    alsoAlertOnDayRow
                }
                .padding(.horizontal, RipeSpacing.s5)
                .padding(.top, RipeSpacing.s5)
                .padding(.bottom, RipeSpacing.s5)
            }
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
            .ripeFlowScreen(
                title: L10n.Expiry.reminderNavTitle,
                leadingTitle: L10n.Common.back,
                onLeading: { store.send(.backTapped) }
            )
        }
    }
}

// MARK: - Subviews

extension ReminderView {
    private var bottomButton: some View {
        saveButton
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.bottom, RipeSpacing.s7)
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
        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
            photoOrMonogramView
        }
        .buttonStyle(.plain)
        .onChange(of: photoItem) { newItem in
            loadPhoto(from: newItem)
        }
    }

    private var photoOrMonogramView: some View {
        Group {
            if let photoImage {
                photoImage
                    .resizable()
                    .scaledToFill()
            } else {
                MonoThumbnail(
                    label: draftItem.name,
                    categoryColor: Color(.ripeAccent),
                    size: 46
                )
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            editPencilBadge
        }
    }

    private var editPencilBadge: some View {
        ZStack {
            Circle()
                .fill(Color(.ripeAccent))
                .overlay {
                    Circle().strokeBorder(Color(.ripeSurface), lineWidth: 2)
                }
            Image(systemName: "pencil")
                .iconFont(.xs)
                .foregroundStyle(.white)
        }
        .frame(width: 20, height: 20)
        .offset(x: 4, y: 4)
    }

    private var itemSummaryTextStack: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(draftItem.name)
                .customFont(.bold17)
                .foregroundStyle(Color(.ripeInk))
                .lineLimit(1)
            Text(L10n.Expiry.bestBefore(shortDate(draftItem.bestBeforeDate)))
                .customFont(.medium12)
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
        Text(L10n.Expiry.remindMe)
            .customFont(.bold13)
            .foregroundStyle(Color(.ripeInk2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
    }

    // MARK: Days readout (no card — accent color per design)

    private var daysReadoutView: some View {
        WithPerceptionTracking {
            HStack(alignment: .firstTextBaseline, spacing: RipeSpacing.s2) {
                Text("\(store.remindDaysBefore)")
                    .customFont(.extrabold44)
                    .foregroundStyle(Color(.ripeAccent))
                    .monospacedDigit()
                Text(L10n.Expiry.daysBefore)
                    .customFont(.semibold18)
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
                Slider(value: sliderBinding, in: 1 ... 60, step: 1)
                    .tint(Color(.ripeAccent))
                sliderMilestoneLabels
            }
        }
    }

    private var sliderMilestoneLabels: some View {
        WithPerceptionTracking {
            GeometryReader { geo in
                milestoneLabelStack(in: geo.size.width)
            }
            .frame(height: 16)
        }
    }

    private func milestoneLabelStack(in totalWidth: CGFloat) -> some View {
        WithPerceptionTracking {
            let thumbInset: CGFloat = 14
            let usableWidth = max(0, totalWidth - 2 * thumbInset)
            ZStack(alignment: .leading) {
                ForEach(milestoneMarks, id: \.self) { mark in
                    milestoneLabel(for: mark, thumbInset: thumbInset, usableWidth: usableWidth)
                }
            }
        }
    }

    private func milestoneLabel(for mark: Int, thumbInset: CGFloat, usableWidth: CGFloat) -> some View {
        WithPerceptionTracking {
            let isActive = mark == store.remindDaysBefore
            let x = thumbInset + CGFloat(mark - 1) / 59 * usableWidth
            Text("\(mark)")
                .customFont(isActive ? .bold12 : .semibold12)
                .foregroundStyle(isActive ? Color(.ripeAccent) : Color(.ripeInk3))
                .monospacedDigit()
                .position(x: x, y: 8)
        }
    }

    // MARK: Banner

    private var reminderBannerView: some View {
        WithPerceptionTracking {
            RipeBanner(
                message: isReminderInPast ? reminderPastHintText : reminderBannerText,
                systemImage: isReminderInPast ? "exclamationmark.octagon.fill" : "bell.fill",
                tone: isReminderInPast ? .danger : .warning
            )
        }
    }

    // MARK: Also-alert-on-day toggle (with green calendar icon per design)

    private var alsoAlertOnDayRow: some View {
        WithPerceptionTracking {
            RipeCard {
                HStack(spacing: 13) {
                    calendarCheckIcon
                    VStack(alignment: .leading, spacing: RipeSpacing.s1) {
                        Text(L10n.Expiry.alsoAlertOnDay)
                            .customFont(.semibold15)
                            .foregroundStyle(Color(.ripeInk))
                        Text(L10n.Expiry.morningOf(shortDate(draftItem.bestBeforeDate)))
                            .customFont(.medium12)
                            .foregroundStyle(Color(.ripeInk2))
                    }
                    Spacer()
                    RipeToggle(
                        isOn: store.remindOnDay,
                        onToggle: { store.remindOnDay = !store.remindOnDay }
                    )
                }
            }
        }
    }

    private var calendarCheckIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.ripeGood).opacity(0.1))
            Image(systemName: "calendar.badge.checkmark")
                .iconFont(.lg)
                .foregroundStyle(Color(.ripeGood))
        }
        .frame(width: 36, height: 36)
    }

    // MARK: Save button

    private var saveButton: some View {
        WithPerceptionTracking {
            RipeButton(
                title: store.isSaving ? L10n.Expiry.saving : L10n.Expiry.saveItem,
                variant: .primary,
                size: .lg,
                fullWidth: true,
                action: { store.send(.saveItemTapped) }
            )
            .disabled(store.isSaving || isReminderInPast)
        }
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

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    photoImage = Image(uiImage: uiImage)
                }
            }
        }
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
            store: Store(initialState: AddExpiryTrackerFeature.State()) { AddExpiryTrackerFeature() },
            draftItem: draft
        )
    }
}
