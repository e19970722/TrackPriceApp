import SwiftUI

/// The direction of a price movement.
/// Raw values match the `direction` field of `GET /trackers/trends`.
public enum PriceDirection: String, Codable, Sendable {
    case up
    case down
}

/// A badge showing a price delta with direction arrow.
/// When `plain` is true, renders as colored text + icon with no background pill.
public struct DeltaBadge: View {
    let direction: PriceDirection
    let value: String
    var plain: Bool

    public init(
        direction: PriceDirection,
        value: String,
        plain: Bool = false
    ) {
        self.direction = direction
        self.value = value
        self.plain = plain
    }

    // MARK: - Body

    public var body: some View {
        if plain {
            plainBadgeView
        } else {
            pillBadgeView
        }
    }
}

// MARK: - Subviews

extension DeltaBadge {
    private var pillBadgeView: some View {
        badgeContentView
            .padding(.horizontal, RipeSpacing.s2)
            .padding(.vertical, RipeSpacing.s1)
            .background(directionBackground, in: Capsule())
            .foregroundStyle(directionForeground)
    }

    private var plainBadgeView: some View {
        badgeContentView
            .foregroundStyle(directionForeground)
    }

    private var badgeContentView: some View {
        HStack(spacing: 3) {
            directionIconView
            deltaValueText
        }
    }

    private var directionIconView: some View {
        Image(systemName: direction == .down ? "arrow.down" : "arrow.up")
            .iconFont(.xs)
    }

    private var deltaValueText: some View {
        Text(value)
            .customFont(.medium12)
            .fontWeight(.bold)
    }
}

// MARK: - Helpers

extension DeltaBadge {
    private var directionForeground: Color {
        switch direction {
        case .down: Color(.ripeGood)
        case .up:   Color(.ripeDanger)
        }
    }

    private var directionBackground: Color {
        switch direction {
        case .down: Color(.ripeGoodSoft)
        case .up:   Color(.ripeDangerSoft)
        }
    }
}

// MARK: - Preview

#Preview("DeltaBadge") {
    VStack(spacing: RipeSpacing.s3) {
        HStack(spacing: RipeSpacing.s3) {
            DeltaBadge(direction: .down, value: "11%")
            DeltaBadge(direction: .up, value: "5%")
        }
        HStack(spacing: RipeSpacing.s3) {
            DeltaBadge(direction: .down, value: "$12.50", plain: true)
            DeltaBadge(direction: .up, value: "$3.99", plain: true)
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("DeltaBadge Dark") {
    HStack(spacing: RipeSpacing.s3) {
        DeltaBadge(direction: .down, value: "11%")
        DeltaBadge(direction: .up, value: "5%")
        DeltaBadge(direction: .down, value: "$12.50", plain: true)
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
