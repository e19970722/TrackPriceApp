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
                .navigationTitle("New Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                }
            }
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
            Image(systemName: "seal.fill")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(Color(.ripeAccent).opacity(0.3))
            Image(systemName: "viewfinder")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(Color(.ripeAccent))
        }
    }

    private var heroTextStack: some View {
        VStack(spacing: RipeSpacing.s2) {
            Text("Track what's in your fridge")
                .font(RipeFont.heading(18))
                .foregroundStyle(Color(.ripeInk))
                .multilineTextAlignment(.center)
            Text("Scan a label and we'll read the best-before date — then nudge you before it turns.")
                .font(RipeFont.caption(13.5))
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
            title: "Scan the label",
            variant: .primary,
            size: .lg,
            systemImage: "camera",
            fullWidth: true,
            action: { store.send(.scanLabelTapped) }
        )
    }

    private var enterManuallyButton: some View {
        RipeButton(
            title: "Enter it myself",
            variant: .ghost,
            size: .lg,
            systemImage: "pencil",
            fullWidth: true,
            action: { store.send(.enterManuallyTapped) }
        )
    }

    private var cancelButton: some View {
        Button("Cancel") {
            store.send(.dismiss)
        }
        .font(RipeFont.body(15))
        .foregroundStyle(Color(.ripeInk2))
    }
}

// MARK: - Preview

#Preview {
    ChooseMethodView(store: Store(initialState: AddItemFeature.State()) { AddItemFeature() })
}
