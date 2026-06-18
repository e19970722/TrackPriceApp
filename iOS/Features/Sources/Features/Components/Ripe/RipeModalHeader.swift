import SwiftUI

/// Sticky header for modal and flow screens. Clears the Dynamic Island with a
/// 56 pt top padding. The title is truly centred because leading and trailing
/// slots share the same 84 pt fixed width.
public struct RipeModalHeader: View {
    let title: String
    var leadingText: String?
    let onLeadingTap: () -> Void
    var trailing: AnyView?

    public init(
        title: String,
        leadingText: String? = nil,
        onLeadingTap: @escaping () -> Void,
        trailing: AnyView? = nil
    ) {
        self.title = title
        self.leadingText = leadingText
        self.onLeadingTap = onLeadingTap
        self.trailing = trailing
    }

    // MARK: - Body

    public var body: some View {
        headerContainerView
    }
}

// MARK: - Subviews

extension RipeModalHeader {
    private var headerContainerView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 56)
            headerRowView
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.bottom, RipeSpacing.s4)
    }

    private var headerRowView: some View {
        HStack(spacing: 0) {
            leadingSlotView
            Spacer()
            titleTextView
            Spacer()
            trailingSlotView
        }
    }

    private var leadingSlotView: some View {
        Button(action: onLeadingTap) {
            leadingSlotContent
        }
        .buttonStyle(.plain)
        .frame(width: 84, alignment: .leading)
    }

    @ViewBuilder
    private var leadingSlotContent: some View {
        if let leadingText {
            Text(leadingText)
                .font(CustomFont.body(16))
                .foregroundStyle(Color(.ripeInk2))
        } else {
            backTileView
        }
    }

    private var backTileView: some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(.ripeInk))
            .frame(width: 38, height: 38)
            .background(
                Circle()
                    .fill(Color(.ripeSurface2))
            )
    }

    private var titleTextView: some View {
        Text(title)
            .font(CustomFont.heading(17))
            .foregroundStyle(Color(.ripeInk))
            .multilineTextAlignment(.center)
    }

    private var trailingSlotView: some View {
        Group {
            if let trailing {
                trailing
            } else {
                Color.clear
            }
        }
        .frame(width: 84, alignment: .trailing)
    }
}

// MARK: - Preview

#Preview("RipeModalHeader — Back icon") {
    VStack(spacing: 0) {
        RipeModalHeader(title: "Add Item", onLeadingTap: {})
        Spacer()
    }
    .background(Color(.ripeBg))
}

#Preview("RipeModalHeader — Cancel text + trailing") {
    VStack(spacing: 0) {
        RipeModalHeader(
            title: "Edit Details",
            leadingText: "Cancel",
            onLeadingTap: {},
            trailing: AnyView(
                Button("Save") {}
                    .font(CustomFont.body(16))
                    .foregroundStyle(Color(.ripeAccent))
            )
        )
        Spacer()
    }
    .background(Color(.ripeBg))
}

#Preview("RipeModalHeader Dark") {
    VStack(spacing: 0) {
        RipeModalHeader(title: "Settings", onLeadingTap: {})
        Spacer()
    }
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
