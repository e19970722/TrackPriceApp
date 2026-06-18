import SwiftUI

/// The semantic tone of a chip, controlling its background and foreground colors.
public enum ChipTone {
    case neutral
    case accent
    case good
    case warn
    case danger
}

/// A pill-shaped label chip with an optional leading SF Symbol.
public struct RipeChip: View {
    let label: String
    var tone: ChipTone
    var systemImage: String?

    public init(
        label: String,
        tone: ChipTone = .neutral,
        systemImage: String? = nil
    ) {
        self.label = label
        self.tone = tone
        self.systemImage = systemImage
    }

    // MARK: - Body

    public var body: some View {
        chipPillView
    }
}

// MARK: - Subviews

extension RipeChip {
    private var chipPillView: some View {
        HStack(spacing: RipeSpacing.s1) {
            if let systemImage {
                chipIconView(systemImage)
            }
            chipLabelText
        }
        .padding(.horizontal, RipeSpacing.s2)
        .padding(.vertical, RipeSpacing.s1)
        .background(toneBackground, in: Capsule())
        .foregroundStyle(toneForeground)
    }

    private func chipIconView(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 10, weight: .bold))
    }

    private var chipLabelText: some View {
        Text(label)
            .font(CustomFont.caption(12))
            .fontWeight(.bold)
    }
}

// MARK: - Helpers

extension RipeChip {
    private var toneBackground: Color {
        switch tone {
        case .neutral: Color(.ripeSurface2)
        case .accent:  Color(.ripeAccentSoft)
        case .good:    Color(.ripeGoodSoft)
        case .warn:    Color(.ripeWarnSoft)
        case .danger:  Color(.ripeDangerSoft)
        }
    }

    private var toneForeground: Color {
        switch tone {
        case .neutral: Color(.ripeInk2)
        case .accent:  Color(.ripeAccent)
        case .good:    Color(.ripeGood)
        case .warn:    Color(.ripeWarn)
        case .danger:  Color(.ripeDanger)
        }
    }
}

// MARK: - Preview

#Preview("RipeChip") {
    VStack(spacing: RipeSpacing.s3) {
        HStack(spacing: RipeSpacing.s2) {
            RipeChip(label: "Neutral")
            RipeChip(label: "Accent", tone: .accent)
            RipeChip(label: "Good", tone: .good)
        }
        HStack(spacing: RipeSpacing.s2) {
            RipeChip(label: "Warn", tone: .warn)
            RipeChip(label: "Danger", tone: .danger)
        }
        HStack(spacing: RipeSpacing.s2) {
            RipeChip(label: "In Stock", tone: .good, systemImage: "checkmark")
            RipeChip(label: "Sale", tone: .accent, systemImage: "tag.fill")
            RipeChip(label: "Low", tone: .warn, systemImage: "exclamationmark.triangle.fill")
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeChip Dark") {
    VStack(spacing: RipeSpacing.s3) {
        HStack(spacing: RipeSpacing.s2) {
            RipeChip(label: "Neutral")
            RipeChip(label: "Accent", tone: .accent)
            RipeChip(label: "Good", tone: .good)
        }
        HStack(spacing: RipeSpacing.s2) {
            RipeChip(label: "Warn", tone: .warn)
            RipeChip(label: "Danger", tone: .danger)
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
