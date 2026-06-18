import SwiftUI

/// Label + hint text wrapper that composes around any input.
/// Supply any input view as the `content` closure.
public struct RipeField<Content: View>: View {
    let label: String?
    let hint: String?
    @ViewBuilder let content: () -> Content

    public init(
        label: String? = nil,
        hint: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        fieldContainerView
    }
}

// MARK: - Subviews

extension RipeField {
    private var fieldContainerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label {
                fieldLabelText(label)
                    .padding(.bottom, 6)
            }
            content()
            if let hint {
                fieldHintText(hint)
                    .padding(.top, 5)
            }
        }
    }

    private func fieldLabelText(_ text: String) -> some View {
        Text(text)
            .customFont(.semibold13)
            .foregroundStyle(Color(.ripeInk2))
    }

    private func fieldHintText(_ text: String) -> some View {
        Text(text)
            .customFont(.medium12)
            .foregroundStyle(Color(.ripeInk3))
    }
}

// MARK: - Preview

#Preview("RipeField") {
    VStack(alignment: .leading, spacing: RipeSpacing.s5) {
        RipeField(label: "Product Name", hint: "Enter the full product title") {
            RipeInputShell {
                Text("Nike Air Max 90")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
        RipeField(label: "Target Price") {
            RipeInputShell {
                Text("$89.99")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
        RipeField(hint: "No label, only hint") {
            RipeInputShell {
                Text("Input value")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeField Dark") {
    VStack(alignment: .leading, spacing: RipeSpacing.s5) {
        RipeField(label: "Store URL", hint: "Paste the product page URL") {
            RipeInputShell(isFocused: true) {
                Text("https://amazon.com/dp/...")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
