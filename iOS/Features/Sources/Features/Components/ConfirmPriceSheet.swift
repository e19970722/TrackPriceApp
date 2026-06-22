import SwiftUI

/// Bottom-sheet content shown over the browser to confirm a picked element
/// (frame 4). Renders the raw element text in a mono block and the detected
/// price as a large read-only readout, plus confirm / pick-again actions.
public struct ConfirmPriceSheet: View {
    let rawText: String?
    let currencySymbol: String
    let detectedPrice: Double?
    let onUsePrice: () -> Void
    let onPickAgain: () -> Void

    public init(
        rawText: String?,
        currencySymbol: String,
        detectedPrice: Double?,
        onUsePrice: @escaping () -> Void,
        onPickAgain: @escaping () -> Void
    ) {
        self.rawText = rawText
        self.currencySymbol = currencySymbol
        self.detectedPrice = detectedPrice
        self.onUsePrice = onUsePrice
        self.onPickAgain = onPickAgain
    }

    // MARK: - Body

    public var body: some View {
        sheetContainerView
    }
}

// MARK: - Subviews

extension ConfirmPriceSheet {
    private var sheetContainerView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s5) {
            grabberView
            headerStack
            rawTextSection
            detectedPriceSection
            helperText
            buttonStack
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.bottom, RipeSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.ripeBg))
    }

    private var grabberView: some View {
        Capsule()
            .fill(Color(.ripeLine))
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, RipeSpacing.s3)
    }

    private var headerStack: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s1) {
            Text(L10n.AddTracker.confirmTitle)
                .customFont(.extrabold22)
                .foregroundStyle(Color(.ripeInk))
            Text(L10n.AddTracker.confirmSubtitle)
                .customFont(.medium13)
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    private var rawTextSection: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            sectionLabelText(L10n.AddTracker.rawElementText)
            rawTextBlock
        }
    }

    private var rawTextBlock: some View {
        Text(displayRawText)
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(Color(.ripeInk))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(RipeSpacing.s3)
            .background(
                RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
                    .fill(Color(.ripeSurface2))
            )
    }

    private var detectedPriceSection: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            sectionLabelText(L10n.AddTracker.detectedPrice)
            detectedPriceReadout
        }
    }

    @ViewBuilder
    private var detectedPriceReadout: some View {
        if let detectedPrice {
            priceValueText(detectedPrice)
        } else {
            noPriceText
        }
    }

    private func priceValueText(_ price: Double) -> some View {
        Text(price.priceFormatted(symbol: displaySymbol))
            .customFont(.extrabold40)
            .foregroundStyle(Color(.ripeInk))
    }

    private var noPriceText: some View {
        Text(L10n.AddTracker.noPriceDetected)
            .customFont(.bold19)
            .foregroundStyle(Color(.ripeWarn))
    }

    private var helperText: some View {
        Text(L10n.AddTracker.confirmHelper)
            .customFont(.medium12)
            .foregroundStyle(Color(.ripeInk3))
    }

    private var buttonStack: some View {
        VStack(spacing: RipeSpacing.s3) {
            RipeButton(
                title: L10n.AddTracker.useThisPrice,
                variant: .primary,
                size: .lg,
                systemImage: "checkmark",
                fullWidth: true,
                cornerRadius: RipeRadius.card,
                action: onUsePrice
            )
            RipeButton(
                title: L10n.AddTracker.pickAgain,
                variant: .ghost,
                size: .lg,
                fullWidth: true,
                action: onPickAgain
            )
        }
    }

    private func sectionLabelText(_ text: String) -> some View {
        Text(text)
            .customFont(.semibold12)
            .foregroundStyle(Color(.ripeInk3))
            .tracking(0.6)
    }
}

// MARK: - Helpers

extension ConfirmPriceSheet {
    private var displayRawText: String {
        guard let rawText, !rawText.isEmpty else { return L10n.AddTracker.noText }
        return rawText
    }

    private var displaySymbol: String {
        currencySymbol.isEmpty ? "$" : currencySymbol
    }
}

// MARK: - Preview

#Preview("ConfirmPriceSheet") {
    ConfirmPriceSheet(
        rawText: "Now $79.00",
        currencySymbol: "$",
        detectedPrice: 79.0,
        onUsePrice: {},
        onPickAgain: {}
    )
    .background(Color(.ripeBg))
}

#Preview("ConfirmPriceSheet — no price") {
    ConfirmPriceSheet(
        rawText: "Add to cart",
        currencySymbol: "",
        detectedPrice: nil,
        onUsePrice: {},
        onPickAgain: {}
    )
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
