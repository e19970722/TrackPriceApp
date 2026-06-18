import SwiftUI

/// A card showing a single labelled value, used inside detail stat grids.
public struct StatCell: View {
    let title: String
    let value: String
    let truncate: Bool

    public init(title: String, value: String, truncate: Bool = false) {
        self.title = title
        self.value = value
        self.truncate = truncate
    }

    // MARK: - Body

    public var body: some View {
        cellContainerView
    }
}

// MARK: - Subviews

extension StatCell {
    private var cellContainerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleLabel
            valueLabel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var titleLabel: some View {
        Text(title)
            .customFont(.regular12)
            .foregroundStyle(.secondary)
    }

    private var valueLabel: some View {
        Text(value)
            .customFont(.medium12)
            .lineLimit(truncate ? 2 : nil)
            .truncationMode(.middle)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCell(title: "URL", value: "https://www.apple.com/shop/buy-mac/macbook-pro", truncate: true)
            StatCell(title: "Created", value: "Dec 1, 2024")
            StatCell(title: "Last Checked", value: "Jan 5, 2025, 3:00 PM")
            StatCell(title: "Next Check", value: "in ~2h 15m")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
#endif
