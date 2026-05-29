import SwiftUI

/// A fixed 48 × 48 pt thumbnail that loads `imageUrl` asynchronously and
/// falls back to a neutral placeholder when the URL is nil or loading fails.
public struct TrackerThumbnailView: View {
    let imageUrl: String?

    public init(imageUrl: String?) {
        self.imageUrl = imageUrl
    }

    // MARK: - Body

    public var body: some View {
        thumbnailView
    }
}

// MARK: - Subviews

extension TrackerThumbnailView {

    @ViewBuilder
    private var thumbnailView: some View {
        if let imageUrl, let url = URL(string: imageUrl) {
            asyncImageView(url: url)
        } else {
            placeholderView
        }
    }

    private func asyncImageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                loadedImageView(image)
            } else {
                placeholderView
            }
        }
    }

    private func loadedImageView(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 48, height: 48)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
            )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        TrackerThumbnailView(imageUrl: nil)
        TrackerThumbnailView(imageUrl: "https://invalid-url")
    }
    .padding()
}
#endif
