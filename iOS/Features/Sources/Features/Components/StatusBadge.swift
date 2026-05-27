import Foundation
import SwiftUI

/// A pill badge that reflects a tracker's active / paused / broken status.
public struct StatusBadge: View {
    let status: TrackerStatus

    public init(status: TrackerStatus) {
        self.status = status
    }

    // MARK: - Body

    public var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.15), in: Capsule())
            .foregroundStyle(badgeColor)
    }

    // MARK: - Helpers

    private var label: String {
        switch status {
        case .active: return "Active"
        case .paused: return "Paused"
        case .broken: return "Broken"
        }
    }

    private var badgeColor: Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .broken: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        StatusBadge(status: .active)
        StatusBadge(status: .paused)
        StatusBadge(status: .broken)
    }
    .padding()
}
#endif
