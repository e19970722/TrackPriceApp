import SwiftUI

/// A two-segment pill selector for choosing the alert direction (Below / Above),
/// following the segmented pattern established by `StoredInSelector`. Each
/// segment pairs an arrow glyph with a label.
public struct DirectionSelector: View {
    @Binding var selection: TargetDirection

    public init(selection: Binding<TargetDirection>) {
        _selection = selection
    }

    // MARK: - Body

    public var body: some View {
        segmentedRowView
    }
}

// MARK: - Subviews

extension DirectionSelector {
    private var segmentedRowView: some View {
        HStack(spacing: RipeSpacing.s2) {
            segmentButton(.below)
            segmentButton(.above)
        }
        .frame(height: 52)
    }

    private func segmentButton(_ direction: TargetDirection) -> some View {
        Button {
            selection = direction
        } label: {
            segmentLabel(direction)
        }
        .buttonStyle(.plain)
    }

    private func segmentLabel(_ direction: TargetDirection) -> some View {
        HStack(spacing: RipeSpacing.s2) {
            Image(systemName: direction.systemImage)
                .iconFont(.sm)
            Text(direction.displayName)
                .customFont(.semibold15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(segmentBackground(for: direction))
        .foregroundStyle(segmentForeground(for: direction))
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous))
    }

    private func segmentBackground(for direction: TargetDirection) -> Color {
        selection == direction ? Color(.ripeAccent) : Color(.ripeSurface2)
    }

    private func segmentForeground(for direction: TargetDirection) -> Color {
        selection == direction ? Color(.ripeAccentInk) : Color(.ripeInk3)
    }
}

// MARK: - Helpers

private extension TargetDirection {
    var systemImage: String {
        switch self {
        case .below: "arrow.down"
        case .above: "arrow.up"
        }
    }

    var displayName: String {
        switch self {
        case .below: L10n.AddTracker.below
        case .above: L10n.AddTracker.above
        }
    }
}

// MARK: - Preview

#Preview("DirectionSelector") {
    StatefulPreviewWrapper(TargetDirection.below) { selection in
        VStack(spacing: RipeSpacing.s5) {
            DirectionSelector(selection: selection)
        }
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
    }
}

#Preview("DirectionSelector Dark") {
    StatefulPreviewWrapper(TargetDirection.above) { selection in
        DirectionSelector(selection: selection)
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
