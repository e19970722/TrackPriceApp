import SwiftUI

/// A section header with an optional tappable action label.
public struct SectionLabel: View {
    let title: String
    var action: String?
    var onAction: (() -> Void)?

    public init(
        title: String,
        action: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    // MARK: - Body

    public var body: some View {
        sectionHeaderRow
    }
}

// MARK: - Subviews

extension SectionLabel {

    private var sectionHeaderRow: some View {
        HStack(alignment: .firstTextBaseline) {
            sectionTitleText
            Spacer()
            if let action, let onAction {
                actionButton(label: action, handler: onAction)
            }
        }
    }

    private var sectionTitleText: some View {
        Text(title)
            .font(RipeFont.heading(19))
            .foregroundStyle(Color(.ripeInk))
    }

    private func actionButton(label: String, handler: @escaping () -> Void) -> some View {
        Button(action: handler) {
            actionLabelText(label)
        }
        .buttonStyle(.plain)
    }

    private func actionLabelText(_ label: String) -> some View {
        Text(label)
            .font(RipeFont.label(13))
            .fontWeight(.semibold)
            .foregroundStyle(Color(.ripeAccent))
    }
}

// MARK: - Preview

#Preview("SectionLabel") {
    VStack(spacing: RipeSpacing.s4) {
        SectionLabel(title: "Tracked Items")
        SectionLabel(
            title: "Recent Alerts",
            action: "See All",
            onAction: {}
        )
        SectionLabel(
            title: "Price History",
            action: "Edit",
            onAction: {}
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("SectionLabel Dark") {
    VStack(spacing: RipeSpacing.s4) {
        SectionLabel(title: "Tracked Items")
        SectionLabel(
            title: "Recent Alerts",
            action: "See All",
            onAction: {}
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
