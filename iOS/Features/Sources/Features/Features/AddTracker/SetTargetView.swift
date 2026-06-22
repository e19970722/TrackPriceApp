import ComposableArchitecture
import SwiftUI

// MARK: - SetTargetView

/// Frame 5 — Set Target. Product summary card, tracker name field, large target
/// price field, Below/Above direction selector, an accent info banner
/// summarizing the alert rule, and a bottom dock with Save. Presents the
/// already-meets-target warning dialog (frame 6) when the current price already
/// satisfies the chosen target.
struct SetTargetView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, targetPrice }

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            ZStack {
                backgroundLayer
                contentLayer
                if store.showsAlreadyMetWarning {
                    alreadyMetDialogView
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .targetPrice
                }
            }
        }
    }
}

// MARK: - Subviews

extension SetTargetView {
    private var backgroundLayer: some View {
        Color(.ripeBg).ignoresSafeArea()
    }

    private var contentLayer: some View {
        VStack(spacing: 0) {
            headerView
            scrollableContentView
            dockView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerView: some View {
        RipeModalHeader(
            title: L10n.AddTracker.navTitleSetTarget,
            onLeadingTap: { store.send(.confirmationRejected) }
        )
    }

    private var scrollableContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s5) {
                productSummaryCard
                trackerNameField
                targetPriceField
                directionField
                infoBannerView
                if let error = store.creationError {
                    errorText(error)
                }
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s2)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var productSummaryCard: some View {
        RipeCard {
            HStack(spacing: RipeSpacing.s3) {
                productThumbnailView
                productInfoStack
                Spacer(minLength: 0)
                currentPriceStack
            }
        }
    }

    private var productThumbnailView: some View {
        MonoThumbnail(
            label: productName,
            categoryColor: Color(.ripeAccent),
            size: 52
        )
    }

    private var productInfoStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(productName)
                .customFont(.bold15)
                .foregroundStyle(Color(.ripeInk))
                .lineLimit(2)
            Text(productHost)
                .customFont(.medium12)
                .foregroundStyle(Color(.ripeInk3))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var currentPriceStack: some View {
        if let current = store.currentPrice {
            VStack(alignment: .trailing, spacing: 2) {
                Text(L10n.AddTracker.currentPriceLabel)
                    .customFont(.medium10)
                    .foregroundStyle(Color(.ripeInk3))
                Text(current.priceFormatted(symbol: currencySymbol))
                    .customFont(.bold17)
                    .foregroundStyle(Color(.ripeInk))
            }
        }
    }

    private var trackerNameField: some View {
        RipeField(label: L10n.AddTracker.trackerNameLabel) {
            RipeInputShell(isFocused: focusedField == .name) {
                HStack(spacing: RipeSpacing.s2) {
                    nameTextField
                    Image(systemName: "pencil")
                        .iconFont(.sm)
                        .foregroundStyle(Color(.ripeInk3))
                }
            }
        }
    }

    private var nameTextField: some View {
        TextField(L10n.AddTracker.trackerNamePlaceholder, text: $store.trackerName)
            .focused($focusedField, equals: .name)
            .customFont(.semibold15)
            .foregroundStyle(Color(.ripeInk))
            .tint(Color(.ripeAccent))
    }

    private var targetPriceField: some View {
        RipeField(label: L10n.AddTracker.targetPriceLabel) {
            RipeInputShell(isFocused: focusedField == .targetPrice) {
                HStack(spacing: RipeSpacing.s2) {
                    Text(currencySymbol)
                        .customFont(.extrabold26)
                        .foregroundStyle(Color(.ripeInk2))
                    targetPriceTextField
                }
            }
        }
    }

    private var targetPriceTextField: some View {
        TextField("0.00", text: $store.targetPriceInput)
            .focused($focusedField, equals: .targetPrice)
            .customFont(.extrabold26)
            .foregroundStyle(Color(.ripeInk))
            .tint(Color(.ripeAccent))
            .keyboardType(.decimalPad)
    }

    private var directionField: some View {
        DirectionSelector(selection: $store.targetDirection)
    }

    private var infoBannerView: some View {
        InfoBanner(message: alertRuleMessage)
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .customFont(.medium12)
            .foregroundStyle(Color(.ripeDanger))
    }

    private var dockView: some View {
        Dock {
            RipeButton(
                title: L10n.AddTracker.save,
                variant: .primary,
                size: .lg,
                systemImage: "checkmark",
                fullWidth: true,
                cornerRadius: RipeRadius.card,
                action: { store.send(.saveTapped) }
            )
        }
    }

    private var alreadyMetDialogView: some View {
        CenteredDialog(
            systemImage: "target",
            title: L10n.AddTracker.alreadyMetTitle,
            message: alreadyMetMessage,
            cancelTitle: L10n.Common.cancel,
            confirmTitle: L10n.AddTracker.saveAnyway,
            onCancel: { store.send(.alreadyMetWarningCancelled) },
            onConfirm: { store.send(.alreadyMetWarningConfirmed) }
        )
    }
}

// MARK: - Helpers

extension SetTargetView {
    private var currencySymbol: String {
        let symbol = store.confirmedElement?.currencySymbol ?? ""
        return symbol.isEmpty ? "$" : symbol
    }

    private var productName: String {
        if !store.trackerName.isEmpty { return store.trackerName }
        return store.confirmedElement?.pageTitle ?? store.currentURL?.host ?? "Product"
    }

    private var productHost: String {
        store.currentURL?.host ?? ""
    }

    private var alertRuleMessage: String {
        let target = (Double(store.targetPriceInput) ?? 0).priceFormatted(symbol: currencySymbol)
        switch store.targetDirection {
        case .below: return L10n.AddTracker.alertBelowInfo(target)
        case .above: return L10n.AddTracker.alertAboveInfo(target)
        }
    }

    private var alreadyMetMessage: String {
        let current = (store.currentPrice ?? 0).priceFormatted(symbol: currencySymbol)
        let target = (Double(store.targetPriceInput) ?? 0).priceFormatted(symbol: currencySymbol)
        return L10n.AddTracker.alreadyMetBody(current, target)
    }
}

// MARK: - Preview

#Preview {
    SetTargetView(store: Store(
        initialState: {
            var state = AddTrackerFeature.State()
            let info = ElementInfo(
                interactions: [
                    InteractionStep(
                        type: "click",
                        locator: ".price",
                        role: "price",
                        rawText: "$129.00",
                        currentPrice: 129.0,
                        currencySymbol: "$"
                    ),
                ],
                pageTitle: "Sony WH-1000XM5"
            )
            state.step = .targetSetup(info)
            state.trackerName = "Sony WH-1000XM5"
            state.targetPriceInput = "99.00"
            state.currentURL = URL(string: "https://store.com/sony")
            return state
        }()
    ) {
        AddTrackerFeature()
    })
}
