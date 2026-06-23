import ComposableArchitecture
import SwiftUI

public struct ItemDetailsView: View {
    @Perception.Bindable var store: StoreOf<AddExpiryTrackerFeature>
    @FocusState private var focusedField: Field?
    @State private var draftBestBeforeDate = Date()

    enum Field: Hashable { case name, locationCustom, quantity }

    public init(store: StoreOf<AddExpiryTrackerFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            scrollFormView
                .safeAreaInset(edge: .bottom) {
                    bottomButton
                }
                .ripeFlowScreen(
                    title: L10n.Expiry.navTitleItemDetails,
                    leadingTitle: L10n.Common.back,
                    onLeading: { store.send(.backTapped) }
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = .name
                    }
                }
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
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s5)
            .padding(.bottom, RipeSpacing.s5)
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: Item name

    private var itemNameFieldCard: some View {
        RipeField(label: L10n.Expiry.fieldItemName) {
            RipeInputShell(isFocused: focusedField == .name) {
                TextField("e.g. Greek Yogurt", text: $store.itemName)
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                    .focused($focusedField, equals: .name)
            }
        }
    }

    // MARK: Stored in

    private var storedInCard: some View {
        WithPerceptionTracking {
            RipeField(label: L10n.Expiry.fieldStoredIn) {
                StoredInSelector(
                    selection: $store.location,
                    customText: $store.locationCustom,
                    focus: $focusedField,
                    focusValue: .locationCustom
                )
            }
        }
    }

    // MARK: Quantity

    private var quantityFieldCard: some View {
        WithPerceptionTracking {
            RipeField(label: L10n.Expiry.fieldQuantity) {
                QuantityStepper(
                    quantity: $store.quantity,
                    decrementDisabled: quantityCount <= 1,
                    focus: $focusedField,
                    focusValue: .quantity,
                    onDecrement: { store.send(.decrementQuantity) },
                    onIncrement: { store.send(.incrementQuantity) }
                )
            }
        }
    }

    private var quantityCount: Int {
        Int(store.quantity) ?? 1
    }

    // MARK: Best-before date

    private var bestBefforeDateCard: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                RipeField(label: L10n.Expiry.fieldBestBeforeDate) {
                    bestBeforeDateButton
                }
                bestBeforeDateHintText
            }
        }
    }

    private var bestBeforeDateButton: some View {
        WithPerceptionTracking {
            Button {
                draftBestBeforeDate = store.bestBeforeDate
                store.send(.datePickerPresented(true))
            } label: {
                RipeInputShell {
                    bestBeforeDateRowContent
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    private var bestBeforeDateRowContent: some View {
        WithPerceptionTracking {
            HStack(spacing: RipeSpacing.s3) {
                Image(systemName: "calendar")
                    .iconFont(.lg)
                    .foregroundStyle(Color(.ripeAccent))
                Text(formattedDate(store.bestBeforeDate))
                    .customFont(.bold17)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
                if store.isDateFromScan {
                    scannedChip
                } else {
                    Image(systemName: "chevron.right")
                        .iconFont(.sm)
                        .foregroundStyle(Color(.ripeInk3))
                }
            }
        }
    }

    private var bestBeforeDateHintText: some View {
        WithPerceptionTracking {
            Text(store.isDateFromScan
                ? "Auto-filled from the label — tap to adjust."
                : "Defaults to today — tap to change.")
                .customFont(.medium12)
                .foregroundStyle(Color(.ripeInk3))
                .padding(.horizontal, 2)
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
                        L10n.Expiry.fieldBestBeforeDate,
                        selection: $draftBestBeforeDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color(.ripeAccent))
                    .padding(RipeSpacing.s5)
                }
                .navigationTitle(L10n.Expiry.navTitleSelectDate)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Common.done) {
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

    // MARK: Bottom button

    private var bottomButton: some View {
        continueButton
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.bottom, RipeSpacing.s7)
    }

    private var continueButton: some View {
        RipeButton(
            title: L10n.Expiry.continueButton,
            variant: .primary,
            size: .lg,
            fullWidth: true,
            action: { store.send(.continueTapped) }
        )
        .disabled(store.itemName.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}

// MARK: - Helpers

extension ItemDetailsView {
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
            initialState: AddExpiryTrackerFeature.State(
                itemName: "Greek Yogurt",
                bestBeforeDate: Date().addingTimeInterval(5 * 86400),
                isDateFromScan: true
            )
        ) { AddExpiryTrackerFeature() })
    }
}
