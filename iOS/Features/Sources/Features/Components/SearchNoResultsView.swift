import SwiftUI

/// Placeholder shown when a search query matches nothing in an otherwise
/// non-empty list. Distinct from a genuinely empty-list state (`RipeEmptyState`).
public struct SearchNoResultsView: View {
    let query: String

    public init(query: String) {
        self.query = query
    }

    // MARK: - Body

    public var body: some View {
        noResultsContent
    }
}

// MARK: - Subviews

extension SearchNoResultsView {
    private var noResultsContent: some View {
        VStack(spacing: RipeSpacing.s3) {
            magnifierIcon
            noResultsLabel
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var magnifierIcon: some View {
        Image(systemName: "magnifyingglass")
            .iconFont(.emptyState)
            .foregroundStyle(Color(.ripeInk3))
    }

    private var noResultsLabel: some View {
        Text(L10n.TrackerList.noResults(query))
            .customFont(.semibold15)
            .foregroundStyle(Color(.ripeInk2))
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        SearchNoResultsView(query: "milk")
    }
#endif
