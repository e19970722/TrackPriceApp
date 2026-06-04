import SwiftUI

/// Storage location options for food items.
public enum StoredInLocation: CaseIterable {
    case fridge
    case pantry
    case freezer
    case others
}

/// 4-segment location picker used in item add/edit flows.
public struct StoredInSelector: View {
    let selected: StoredInLocation
    let onSelect: (StoredInLocation) -> Void

    public init(
        selected: StoredInLocation,
        onSelect: @escaping (StoredInLocation) -> Void
    ) {
        self.selected = selected
        self.onSelect = onSelect
    }

    // MARK: - Body

    public var body: some View {
        segmentedRowView
    }
}

// MARK: - Subviews

extension StoredInSelector {
    private var segmentedRowView: some View {
        HStack(spacing: RipeSpacing.s2) {
            ForEach(StoredInLocation.allCases, id: \.self) { location in
                segmentButton(location)
            }
        }
        .frame(height: 52)
    }

    private func segmentButton(_ location: StoredInLocation) -> some View {
        Button {
            onSelect(location)
        } label: {
            segmentLabel(location)
        }
        .buttonStyle(.plain)
    }

    private func segmentLabel(_ location: StoredInLocation) -> some View {
        VStack(spacing: 4) {
            Image(systemName: location.systemImage)
                .font(.system(size: 16, weight: .semibold))
            Text(location.displayName)
                .font(CustomFont.caption(11))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(segmentBackground(for: location))
        .foregroundStyle(segmentForeground(for: location))
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous))
    }

    private func segmentBackground(for location: StoredInLocation) -> Color {
        selected == location ? Color(.ripeAccent) : Color(.ripeSurface2)
    }

    private func segmentForeground(for location: StoredInLocation) -> Color {
        selected == location ? Color(.ripeAccentInk) : Color(.ripeInk3)
    }
}

// MARK: - Helpers

private extension StoredInLocation {
    var systemImage: String {
        switch self {
        case .fridge:  "refrigerator"
        case .pantry:  "cabinet"
        case .freezer: "snowflake"
        case .others:  "ellipsis"
        }
    }

    var displayName: String {
        switch self {
        case .fridge:  "Fridge"
        case .pantry:  "Pantry"
        case .freezer: "Freezer"
        case .others:  "Others"
        }
    }
}

// MARK: - Preview

#Preview("StoredInSelector") {
    VStack(spacing: RipeSpacing.s5) {
        StoredInSelector(selected: .fridge, onSelect: { _ in })
        StoredInSelector(selected: .pantry, onSelect: { _ in })
        StoredInSelector(selected: .freezer, onSelect: { _ in })
        StoredInSelector(selected: .others, onSelect: { _ in })
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("StoredInSelector Dark") {
    StoredInSelector(selected: .fridge, onSelect: { _ in })
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
        .preferredColorScheme(.dark)
}
