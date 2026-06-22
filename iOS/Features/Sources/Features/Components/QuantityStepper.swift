import SwiftUI

/// Reusable +/- quantity stepper matching the Ripe design spec.
/// The middle slot is an editable text field bound to a `String`.
public struct QuantityStepper: View {
    @Binding var quantity: String
    let decrementDisabled: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    @FocusState private var isFieldFocused: Bool

    public init(
        quantity: Binding<String>,
        decrementDisabled: Bool = false,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) {
        _quantity = quantity
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
            quantityField
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

    private var quantityField: some View {
        RipeInputShell(isFocused: isFieldFocused) {
            quantityTextField
        }
        .frame(minWidth: 72)
    }

    private var quantityTextField: some View {
        TextField("1", text: $quantity)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .focused($isFieldFocused)
            .customFont(.bold19)
            .monospacedDigit()
            .foregroundStyle(Color(.ripeInk))
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

private struct QuantityStepperPreviewWrapper: View {
    @State private var defaultQty: String = "1"
    @State private var multiDigitQty: String = "12"
    @State private var disabledQty: String = "1"

    var body: some View {
        VStack(spacing: RipeSpacing.s5) {
            QuantityStepper(
                quantity: $defaultQty,
                onDecrement: {},
                onIncrement: {}
            )
            QuantityStepper(
                quantity: $multiDigitQty,
                onDecrement: {},
                onIncrement: {}
            )
            QuantityStepper(
                quantity: $disabledQty,
                decrementDisabled: true,
                onDecrement: {},
                onIncrement: {}
            )
        }
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
    }
}

#Preview("QuantityStepper") {
    QuantityStepperPreviewWrapper()
}

#Preview("QuantityStepper Dark") {
    QuantityStepperPreviewWrapper()
        .preferredColorScheme(.dark)
}
