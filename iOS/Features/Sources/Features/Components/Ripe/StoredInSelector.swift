import SwiftUI

/// 4-segment location picker used in item add/edit flows.
/// When `customText` is provided and the selection is `.custom`, an inline
/// text field is rendered below the segmented row for free-form entry.
///
/// Focus for the inline custom-spot field is owned by the parent screen: pass
/// its `@FocusState` binding plus the value representing this field. A
/// background tap that clears the parent's `@FocusState` then dismisses this
/// field's keyboard too. When no binding is supplied (e.g. previews) the field
/// manages focus internally.
public struct StoredInSelector<FocusValue: Hashable>: View {
    @Binding var selection: ItemLocation
    var customText: Binding<String>?

    private let externalFocus: FocusState<FocusValue?>.Binding?
    private let focusValue: FocusValue?

    @FocusState private var internalFocus: Bool

    public init(
        selection: Binding<ItemLocation>,
        customText: Binding<String>? = nil,
        focus: FocusState<FocusValue?>.Binding,
        focusValue: FocusValue
    ) {
        _selection = selection
        self.customText = customText
        externalFocus = focus
        self.focusValue = focusValue
    }

    private init(
        selection: Binding<ItemLocation>,
        customText: Binding<String>?,
        externalFocus: FocusState<FocusValue?>.Binding?,
        focusValue: FocusValue?
    ) {
        _selection = selection
        self.customText = customText
        self.externalFocus = externalFocus
        self.focusValue = focusValue
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
                customTextField(binding)
            }
        }
    }

    @ViewBuilder
    private func customTextField(_ binding: Binding<String>) -> some View {
        let field = TextField("Type a custom spot", text: binding)
            .customFont(.semibold15)
            .foregroundStyle(Color(.ripeInk))
            .tint(Color(.ripeAccent))
        if let externalFocus, let focusValue {
            field.focused(externalFocus, equals: focusValue)
        } else {
            field.focused($internalFocus)
        }
    }
}

/// A self-managed focus placeholder used when no external `@FocusState` is
/// supplied (e.g. previews).
public enum StoredInSelectorSelfFocus: Hashable { case customField }

public extension StoredInSelector where FocusValue == StoredInSelectorSelfFocus {
    /// Creates a selector that manages its own custom-field focus internally.
    init(
        selection: Binding<ItemLocation>,
        customText: Binding<String>? = nil
    ) {
        self.init(
            selection: selection,
            customText: customText,
            externalFocus: nil,
            focusValue: nil
        )
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
