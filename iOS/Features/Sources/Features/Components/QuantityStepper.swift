import SwiftUI

/// Reusable +/- quantity stepper matching the Ripe design spec.
/// The label is rendered as-is; callers store quantity as a `String`.
public struct QuantityStepper: View {
    let quantity: String
    let decrementDisabled: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    public init(
        quantity: String,
        decrementDisabled: Bool = false,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) {
        self.quantity = quantity
        self.decrementDisabled = decrementDisabled
        self.onDecrement = onDecrement
        self.onIncrement = onIncrement
    }

    // MARK: - Body

    public var body: some View {
        stepperRowView
    }
}

// MARK: - Subviews

extension QuantityStepper {
    private var stepperRowView: some View {
        HStack(spacing: RipeSpacing.s3) {
            decrementButton
            quantityLabel
            incrementButton
        }
    }

    private var decrementButton: some View {
        Button(action: onDecrement) {
            decrementTileView
        }
        .buttonStyle(.plain)
        .disabled(decrementDisabled)
    }

    private var decrementTileView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
                .fill(Color(.ripeSurface2))
                .overlay(
                    RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
                        .strokeBorder(Color(.ripeInk).opacity(0.07), lineWidth: 1.5)
                )
            Image(systemName: "minus")
                .iconFont(.quantityLg)
                .foregroundStyle(decrementDisabled ? Color(.ripeInk3) : Color(.ripeInk2))
        }
        .frame(width: 52, height: 52)
        .contentShape(RoundedRectangle(cornerRadius: RipeRadius.sm))
    }

    private var quantityLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
                .fill(Color(.ripeSurface))
                .overlay(
                    RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
                        .strokeBorder(Color(.ripeInk).opacity(0.07), lineWidth: 1.5)
                )
            Text(quantity)
                .customFont(.bold22)
                .foregroundStyle(Color(.ripeInk))
                .monospacedDigit()
                .fontWeight(.heavy)
        }
        .frame(height: 52)
    }

    private var incrementButton: some View {
        Button(action: onIncrement) {
            incrementTileView
        }
        .buttonStyle(.plain)
    }

    private var incrementTileView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
                .fill(Color(.ripeAccent))
                .shadow(color: Color(.ripeAccent).opacity(0.3), radius: 5, y: 3)
            Image(systemName: "plus")
                .iconFont(.quantityLg)
                .foregroundStyle(Color(.ripeAccentInk))
        }
        .frame(width: 52, height: 52)
        .contentShape(RoundedRectangle(cornerRadius: RipeRadius.sm))
    }
}

// MARK: - Preview

#Preview("QuantityStepper") {
    VStack(spacing: RipeSpacing.s5) {
        QuantityStepper(
            quantity: "1",
            decrementDisabled: true,
            onDecrement: {},
            onIncrement: {}
        )
        QuantityStepper(
            quantity: "3",
            onDecrement: {},
            onIncrement: {}
        )
        QuantityStepper(
            quantity: "12",
            onDecrement: {},
            onIncrement: {}
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("QuantityStepper Dark") {
    QuantityStepper(
        quantity: "5",
        onDecrement: {},
        onIncrement: {}
    )
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
