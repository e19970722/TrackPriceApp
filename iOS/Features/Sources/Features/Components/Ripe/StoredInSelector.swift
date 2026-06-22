import SwiftUI

/// 4-segment location picker used in item add/edit flows.
/// When `customText` is provided and the selection is `.custom`, an inline
/// text field is rendered below the segmented row for free-form entry.
public struct StoredInSelector: View {
    @Binding var selection: ItemLocation
    var customText: Binding<String>?

    public init(
        selection: Binding<ItemLocation>,
        customText: Binding<String>? = nil
    ) {
        _selection = selection
        self.customText = customText
    }

    // MARK: - Body

    public var body: some View {
        selectorStackView
    }
}

// MARK: - Subviews

extension StoredInSelector {
    private var selectorStackView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            segmentedRowView
            if shouldShowCustomField {
                customTextFieldView
            }
        }
    }

    private var segmentedRowView: some View {
        HStack(spacing: RipeSpacing.s2) {
            ForEach(ItemLocation.allCases, id: \.self) { location in
                segmentButton(location)
            }
        }
        .frame(height: 52)
    }

    private func segmentButton(_ location: ItemLocation) -> some View {
        Button {
            selection = location
        } label: {
            segmentLabel(location)
        }
        .buttonStyle(.plain)
    }

    private func segmentLabel(_ location: ItemLocation) -> some View {
        VStack(spacing: 4) {
            Image(systemName: location.selectorSystemImage)
                .iconFont(.quantity)
            Text(location.selectorDisplayName)
                .customFont(.medium11)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(segmentBackground(for: location))
        .foregroundStyle(segmentForeground(for: location))
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous))
    }

    private func segmentBackground(for location: ItemLocation) -> Color {
        selection == location ? Color(.ripeAccent) : Color(.ripeSurface2)
    }

    private func segmentForeground(for location: ItemLocation) -> Color {
        selection == location ? Color(.ripeAccentInk) : Color(.ripeInk3)
    }

    @ViewBuilder
    private var customTextFieldView: some View {
        if let binding = customText {
            RipeInputShell {
                TextField("Type a custom spot", text: binding)
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                    .tint(Color(.ripeAccent))
            }
        }
    }
}

// MARK: - Helpers

extension StoredInSelector {
    private var shouldShowCustomField: Bool {
        customText != nil && selection == .custom
    }
}

private extension ItemLocation {
    var selectorSystemImage: String {
        switch self {
        case .fridge:  "refrigerator"
        case .pantry:  "cabinet"
        case .freezer: "snowflake"
        case .custom:  "ellipsis"
        }
    }

    var selectorDisplayName: String {
        switch self {
        case .fridge:  "Fridge"
        case .pantry:  "Pantry"
        case .freezer: "Freezer"
        case .custom:  "Others"
        }
    }
}

// MARK: - Preview

#Preview("StoredInSelector") {
    StatefulPreviewWrapper(ItemLocation.fridge) { selection in
        VStack(spacing: RipeSpacing.s5) {
            StoredInSelector(selection: selection)
        }
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
    }
}

#Preview("StoredInSelector with Custom Text") {
    StatefulPreviewWrapper(ItemLocation.custom) { selection in
        StatefulPreviewWrapper("Spice rack") { customText in
            VStack(spacing: RipeSpacing.s5) {
                StoredInSelector(
                    selection: selection,
                    customText: customText
                )
            }
            .padding(RipeSpacing.s5)
            .background(Color(.ripeBg))
        }
    }
}

#Preview("StoredInSelector Dark") {
    StatefulPreviewWrapper(ItemLocation.fridge) { selection in
        StoredInSelector(selection: selection)
            .padding(RipeSpacing.s5)
            .background(Color(.ripeBg))
            .preferredColorScheme(.dark)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    let content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
