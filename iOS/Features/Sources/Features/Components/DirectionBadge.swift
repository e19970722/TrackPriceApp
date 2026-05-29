import Foundation
import SwiftUI

/// A pill badge that reflects a tracker's target direction (below / above).
public struct DirectionBadge: View {
    let direction: TargetDirection

    public init(direction: TargetDirection) {
        self.direction = direction
    }

    // MARK: - Body

    public var body: some View {
        badgePillView
    }
}

// MARK: - Subviews

extension DirectionBadge {

    private var badgePillView: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(label)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.15), in: Capsule())
        .foregroundStyle(badgeColor)
    }
}

// MARK: - Helpers

extension DirectionBadge {

    private var label: String {
        direction == .below ? "Below" : "Above"
    }

    private var iconName: String {
        direction == .below ? "arrow.down" : "arrow.up"
    }

    private var badgeColor: Color {
        direction == .below ? .green : .orange
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        DirectionBadge(direction: .below)
        DirectionBadge(direction: .above)
    }
    .padding()
}
#endif
