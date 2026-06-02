import ComposableArchitecture
import SwiftUI

public struct ItemDetailsView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, quantity, customLocation }

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

    // MARK: Stored in

    private var storedInCard: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            fieldSectionLabel("Stored in")
            locationPresetPicker
            othersRow
        }
    }

    private var locationPresetPicker: some View {
        HStack(spacing: RipeSpacing.s2) {
            ForEach([ItemLocation.fridge, .pantry, .freezer], id: \.self) { loc in
                locationPresetButton(loc)
            }
        }
    }

    private func locationPresetButton(_ loc: ItemLocation) -> some View {
        let isSelected = store.location == loc
        return Button {
            store.send(.set(\.location, loc))
        } label: {
            HStack(spacing: 7) {
                Image(systemName: loc.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(loc.displayName)
                    .font(RipeFont.heading(14))
            }
            .foregroundStyle(isSelected ? Color(.ripeAccentInk) : Color(.ripeInk3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(.ripeAccent) : Color(.ripeSurface2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .ripeShadow(isSelected ? .soft : RipeShadow(color: .clear, radius: 0, x: 0, y: 0))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: store.location)
    }

    private var othersRow: some View {
        Button {
            store.send(.set(\.location, .custom))
            focusedField = .customLocation
        } label: {
            othersRowContent
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var othersRowContent: some View {
        HStack(spacing: 9) {
            Image(systemName: "pencil")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.ripeInk3))
            if store.location == .custom {
                TextField("Type a custom spot", text: $store.locationCustom)
                    .font(RipeFont.body(14))
                    .foregroundStyle(Color(.ripeInk))
                    .focused($focusedField, equals: .customLocation)
                    .tint(Color(.ripeAccent))
            } else {
                Text("Others — type a custom spot")
                    .font(RipeFont.body(14))
                    .foregroundStyle(Color(.ripeInk3))
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, RipeSpacing.s4)
        .padding(.vertical, 12)
        .background(Color(.ripeSurface2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Quantity

    private var quantityFieldCard: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            fieldSectionLabel("Quantity")
            RipeCard {
                TextField("e.g. 2 cups", text: $store.quantity)
                    .font(RipeFont.body(15))
                    .foregroundStyle(Color(.ripeInk))
                    .focused($focusedField, equals: .quantity)
            }
        }
    }

    // MARK: Best-before date

    private var bestBefforeDateCard: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            fieldSectionLabel("Best-before date")
            RipeCard {
                HStack {
                    Text(formattedDate(store.bestBeforeDate))
                        .font(RipeFont.body(15))
                        .foregroundStyle(Color(.ripeInk))
                    Spacer()
                    if store.isDateFromScan {
                        scannedChip
                    }
                    Image(systemName: "calendar")
                        .foregroundStyle(Color(.ripeInk3))
                }
            }
            .onTapGesture {
                store.send(.datePickerPresented(true))
            }
        }
    }

    private var scannedChip: some View {
        RipeChip(label: "scanned", tone: .accent, systemImage: "viewfinder")
    }

    // MARK: Date picker sheet

    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Best-before date",
                    selection: Binding(
                        get: { store.bestBeforeDate },
                        set: { store.send(.bestBeforeDateChanged($0)) }
                    ),
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
                    Button("Done") { store.send(.datePickerPresented(false)) }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: Action buttons

    private var actionButtonsView: some View {
        VStack(spacing: RipeSpacing.s3) {
            continueButton
            scanAgainButton
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

    private var scanAgainButton: some View {
        RipeButton(
            title: "Scan again",
            variant: .ghost,
            size: .lg,
            fullWidth: true,
            action: { store.send(.scanAgainTapped) }
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
