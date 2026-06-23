import ComposableArchitecture
import SwiftUI

public struct SavedView: View {
    @Perception.Bindable var store: StoreOf<AddExpiryTrackerFeature>
    let savedItem: Item

    public init(store: StoreOf<AddExpiryTrackerFeature>, savedItem: Item) {
        self.store = store
        self.savedItem = savedItem
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.ripeBg).ignoresSafeArea()
                savedContentView
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Subviews

extension SavedView {
    private var savedContentView: some View {
        VStack(spacing: RipeSpacing.s6) {
            Spacer()
            successIconView
            confirmationTextStack
            Spacer()
            actionButtonsView
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.bottom, RipeSpacing.s7)
    }

    private var successIconView: some View {
        ZStack {
            Circle()
                .fill(Color(.ripeGoodSoft))
                .frame(width: 120, height: 120)
            Image(systemName: "checkmark")
                .iconFont(.heroSolid)
                .foregroundStyle(Color(.ripeGood))
        }
    }

    private var confirmationTextStack: some View {
        VStack(spacing: RipeSpacing.s3) {
            Text(L10n.Expiry.savedAllSet)
                .customFont(.extrabold34)
                .foregroundStyle(Color(.ripeInk))
            Text(confirmationBody)
                .customFont(.semibold15)
                .foregroundStyle(Color(.ripeInk2))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RipeSpacing.s4)
        }
    }

    private var actionButtonsView: some View {
        VStack(spacing: RipeSpacing.s3) {
            viewItemButton
            addAnotherButton
        }
    }

    private var viewItemButton: some View {
        RipeButton(
            title: L10n.Expiry.viewItem,
            variant: .primary,
            size: .lg,
            fullWidth: true,
            action: { store.send(.viewItemTapped(savedItem)) }
        )
    }

    private var addAnotherButton: some View {
        RipeButton(
            title: L10n.Expiry.addAnother,
            variant: .ghost,
            size: .lg,
            fullWidth: true,
            action: { store.send(.addAnotherTapped) }
        )
    }
}

// MARK: - Helpers

extension SavedView {
    private var confirmationBody: String {
        let days = savedItem.remindDaysBefore
        return "\(savedItem.name) is in your \(savedItem.locationLabel). We'll remind you \(days) day\(days == 1 ? "" : "s") before it expires."
    }
}

// MARK: - Preview

#Preview {
    let item = Item(
        name: "Greek Yogurt",
        quantity: "2 cups",
        location: .fridge,
        bestBeforeDate: Date().addingTimeInterval(5 * 86400),
        remindDaysBefore: 3
    )
    NavigationStack {
        SavedView(
            store: Store(initialState: AddExpiryTrackerFeature.State()) { AddExpiryTrackerFeature() },
            savedItem: item
        )
    }
}
