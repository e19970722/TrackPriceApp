import ComposableArchitecture
import SwiftUI

public struct ChooseMethodView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>

    public init(store: StoreOf<AddItemFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    Color(.ripeBg).ignoresSafeArea()
                    methodSelectionContent
                }
                .navigationTitle(L10n.Expiry.newItemNavTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                }
            }
            .tint(Color(.ripeInk2))
        }
    }
}

// MARK: - Subviews

extension ChooseMethodView {
    private var methodSelectionContent: some View {
        VStack(spacing: RipeSpacing.s6) {
            Spacer()
            heroCardView
            Spacer()
            ctaStackView
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.bottom, RipeSpacing.s7)
    }

    private var heroCardView: some View {
        RipeCard {
            VStack(spacing: RipeSpacing.s4) {
                heroIllustrationView
                heroTextStack
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RipeSpacing.s4)
        }
    }

    private var heroIllustrationView: some View {
        ZStack {
            Circle()
                .fill(Color(.ripeAccentSoft))
                .frame(width: 120, height: 120)
            Image(systemName: "refrigerator.fill")
                .iconFont(.hero)
                .foregroundStyle(Color(.ripeAccent))
        }
    }

    private var heroTextStack: some View {
        VStack(spacing: RipeSpacing.s2) {
            Text(L10n.Expiry.firstPageTitle)
                .customFont(.bold18)
                .foregroundStyle(Color(.ripeInk))
                .multilineTextAlignment(.center)

            Text(L10n.Expiry.firstPageDesc)
                .customFont(.medium13)
                .foregroundStyle(Color(.ripeInk2))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RipeSpacing.s3)
        }
    }

    private var ctaStackView: some View {
        VStack(spacing: RipeSpacing.s3) {
            scanLabelButton
            enterManuallyButton
        }
    }

    private var scanLabelButton: some View {
        RipeButton(
            title: L10n.Expiry.scanTheLabel,
            variant: .primary,
            size: .lg,
            systemImage: "camera",
            fullWidth: true,
            cornerRadius: RipeRadius.card,
            action: { store.send(.scanLabelTapped) }
        )
    }

    private var enterManuallyButton: some View {
        RipeButton(
            title: L10n.Expiry.enterManually,
            variant: .ghost,
            size: .lg,
            systemImage: "pencil",
            fullWidth: true,
            action: { store.send(.enterManuallyTapped) }
        )
    }

    private var cancelButton: some View {
        Button(L10n.Common.cancel) {
            store.send(.dismiss)
        }
        .customFont(.semibold15)
        .foregroundStyle(Color(.ripeInk2))
    }
}

// MARK: - Preview

#Preview {
    ChooseMethodView(store: Store(initialState: AddItemFeature.State()) { AddItemFeature() })
}
