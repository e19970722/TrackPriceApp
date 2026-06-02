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
            locationSegmentedPicker
            if store.location == .custom {
                customLocationFieldCard
            }
        }
    }

    private var locationSegmentedPicker: some View {
        HStack(spacing: 0) {
            ForEach(ItemLocation.allCases, id: \.self) { loc in
                locationSegmentButton(loc)
            }
        }
        .padding(RipeSpacing.s1)
        .background(Color(.ripeSurface2))
        .clipShape(Capsule())
    }

    private func locationSegmentButton(_ loc: ItemLocation) -> some View {
        let isSelected = store.location == loc
        return Button {
            store.send(.set(\.location, loc))
        } label: {
            VStack(spacing: 2) {
                Image(systemName: loc.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(loc.displayName)
                    .font(RipeFont.caption(11))
            }
            .foregroundStyle(isSelected ? Color(.ripeInk) : Color(.ripeInk3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, RipeSpacing.s2)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(Color(.ripeSurface)).ripeShadow(.soft)
                    } else {
                        Capsule().fill(Color.clear)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    private var customLocationFieldCard: some View {
        RipeCard {
            TextField("Custom location", text: $store.locationCustom)
                .font(RipeFont.body(15))
                .foregroundStyle(Color(.ripeInk))
                .focused($focusedField, equals: .customLocation)
        }
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
