import ComposableArchitecture
import SwiftUI

public struct ItemDetailsView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>
    @FocusState private var focusedField: Field?
    @State private var draftBestBeforeDate = Date()
    private let locationButtonHeight: CGFloat = 46

    enum Field: Hashable { case name, customLocation }

    public init(store: StoreOf<AddItemFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg).ignoresSafeArea()
                scrollFormView
            }
            .navigationTitle("Item details")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { store.isDatePickerPresented },
                set: { store.send(.datePickerPresented($0)) }
            )) {
                datePickerSheet
            }
        }
    }
}

// MARK: - Subviews

extension ItemDetailsView {
    private var scrollFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s5) {
                itemNameFieldCard
                storedInCard
                quantityFieldCard
                bestBefforeDateCard
                actionButtonsView
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s5)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    // MARK: Item name

    private var itemNameFieldCard: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            fieldSectionLabel("Item name")
            RipeCard {
                TextField("e.g. Greek Yogurt", text: $store.itemName)
                    .font(RipeFont.body(15))
                    .foregroundStyle(Color(.ripeInk))
                    .focused($focusedField, equals: .name)
            }
        }
    }

    // MARK: Stored in — 2-row layout matching design

    private var storedInCard: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            fieldSectionLabel("Stored in")
            primaryLocationRow
            othersRow
        }
    }

    private var primaryLocationRow: some View {
        HStack(spacing: RipeSpacing.s2) {
            locationButton(.fridge)
            locationButton(.pantry)
            locationButton(.freezer)
        }
    }

    private var othersRow: some View {
        GeometryReader { geo in
            let gap = CGFloat(RipeSpacing.s2)
            let unitW = (geo.size.width - 2 * gap) / 3
            HStack(spacing: gap) {
                locationButton(.custom)
                    .frame(width: unitW)
                customLocationTextField
            }
        }
        .frame(height: locationButtonHeight)
    }

    private func locationButton(_ loc: ItemLocation) -> some View {
        WithPerceptionTracking {
            let isSelected = store.location == loc
            let image = loc == .custom ? "pencil" : loc.systemImage
            let label = loc == .custom ? "Others" : loc.displayName
            return Button {
                store.send(.set(\.location, loc))
                if loc == .custom { focusedField = .customLocation }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: image)
                        .font(.system(size: 15, weight: .semibold))
                    Text(label)
                        .font(RipeFont.heading(13))
                }
                .foregroundStyle(isSelected ? Color(.ripeAccentInk) : Color(.ripeInk3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? Color(.ripeAccent) : Color(.ripeSurface2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: store.location)
        }
    }

    private var customLocationTextField: some View {
        WithPerceptionTracking {
            TextField("Type a custom spot", text: $store.locationCustom)
                .font(RipeFont.body(14))
                .foregroundStyle(Color(.ripeInk))
                .focused($focusedField, equals: .customLocation)
                .tint(Color(.ripeAccent))
                .disabled(store.location != .custom)
                .padding(.horizontal, RipeSpacing.s3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.ripeSurface2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(store.location == .custom ? 1 : 0.5)
        }
    }

    // MARK: Quantity — stepper with rounded-rect buttons (design: 52×52, r=14)

    private var quantityCount: Int { Int(store.quantity) ?? 1 }

    private var quantityFieldCard: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            fieldSectionLabel("Quantity")
            HStack(spacing: 12) {
                decrementButton
                quantityLabel
                incrementButton
            }
        }
    }

    private var decrementButton: some View {
        WithPerceptionTracking {
            Button {
                store.send(.decrementQuantity)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.ripeSurface2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(.ripeInk).opacity(0.07), lineWidth: 1.5)
                        )
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(quantityCount <= 1 ? Color(.ripeInk3) : Color(.ripeInk2))
                }
                .frame(width: 52, height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(quantityCount <= 1)
        }
    }

    private var quantityLabel: some View {
        WithPerceptionTracking {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.ripeSurface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(.ripeInk).opacity(0.07), lineWidth: 1.5)
                    )
                Text("\(quantityCount)")
                    .font(RipeFont.num(22))
                    .foregroundStyle(Color(.ripeInk))
                    .monospacedDigit()
                    .fontWeight(.heavy)
            }
            .frame(height: 52)
        }
    }

    private var incrementButton: some View {
        Button {
            store.send(.incrementQuantity)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.ripeAccent))
                    .shadow(color: Color(.ripeAccent).opacity(0.3), radius: 5, y: 3)
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(.ripeAccentInk))
            }
            .frame(width: 52, height: 52)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: Best-before date — calendar icon on left, hint below

    private var bestBefforeDateCard: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                fieldSectionLabel("Best-before date")
                Button {
                    draftBestBeforeDate = store.bestBeforeDate
                    store.send(.datePickerPresented(true))
                } label: {
                    RipeCard {
                        HStack(spacing: RipeSpacing.s3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color(.ripeAccent))
                            Text(formattedDate(store.bestBeforeDate))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(.ripeInk))
                            Spacer()
                            if store.isDateFromScan {
                                scannedChip
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(.ripeInk3))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                Text(store.isDateFromScan
                    ? "Auto-filled from the label — tap to adjust."
                    : "Defaults to today — tap to change.")
                    .font(RipeFont.caption(12))
                    .foregroundStyle(Color(.ripeInk3))
                    .padding(.horizontal, 2)
            }
        }
    }

    private var scannedChip: some View {
        RipeChip(label: "scanned", tone: .accent, systemImage: "viewfinder")
    }

    // MARK: Date picker sheet

    private var datePickerSheet: some View {
        WithPerceptionTracking {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Best-before date",
                        selection: $draftBestBeforeDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color(.ripeAccent))
                    .padding(RipeSpacing.s5)
                }
                .navigationTitle("Select date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            store.send(.bestBeforeDateChanged(draftBestBeforeDate))
                            store.send(.datePickerPresented(false))
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .onAppear {
                draftBestBeforeDate = store.bestBeforeDate
            }
        }
    }

    // MARK: Action buttons

    private var actionButtonsView: some View {
        VStack(spacing: RipeSpacing.s3) {
            continueButton
            backButton
        }
    }

    private var continueButton: some View {
        RipeButton(
            title: "Continue",
            variant: .primary,
            size: .lg,
            fullWidth: true,
            action: { store.send(.continueTapped) }
        )
        .disabled(store.itemName.trimmingCharacters(in: .whitespaces).isEmpty)
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

extension ItemDetailsView {
    private func fieldSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(RipeFont.label(12))
            .foregroundStyle(Color(.ripeInk3))
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        return df.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ItemDetailsView(store: Store(
            initialState: AddItemFeature.State(
                itemName: "Greek Yogurt",
                bestBeforeDate: Date().addingTimeInterval(5 * 86400),
                isDateFromScan: true
            )
        ) { AddItemFeature() })
    }
}
