import SwiftUI

/// A monogram or icon thumbnail for a tracker category.
/// Light mode: tinted background derived from `categoryColor`.
/// Dark mode: neutral surface background with `ripeInk` foreground.
public struct MonoThumbnail: View {
    let label: String
    let categoryColor: Color
    var size: CGFloat
    var round: Bool
    var systemImage: String?

    public init(
        label: String,
        categoryColor: Color,
        size: CGFloat = 48,
        round: Bool = false,
        systemImage: String? = nil
    ) {
        self.label = label
        self.categoryColor = categoryColor
        self.size = size
        self.round = round
        self.systemImage = systemImage
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    public var body: some View {
        thumbnailContainerView
    }
}

// MARK: - Subviews

extension MonoThumbnail {
    private var thumbnailContainerView: some View {
        thumbnailContentView
            .frame(width: size, height: size)
            .background(thumbnailBackgroundView)
    }

    @ViewBuilder
    private var thumbnailContentView: some View {
        if let systemImage {
            thumbnailIconView(systemImage)
        } else {
            thumbnailLetterText
        }
    }

    private func thumbnailIconView(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(thumbnailForeground)
    }

    private var thumbnailLetterText: some View {
        Text(String(label.prefix(1)).uppercased())
            .font(RipeFont.display(size * 0.4))
            .foregroundStyle(thumbnailForeground)
    }

    private var thumbnailBackgroundView: some View {
        RoundedRectangle(
            cornerRadius: round ? RipeRadius.pill : RipeRadius.control,
            style: .continuous
        )
        .fill(thumbnailBackground)
    }
}

// MARK: - Helpers

extension MonoThumbnail {
    private var thumbnailBackground: Color {
        colorScheme == .dark
            ? Color(.ripeSurface2)
            : categoryColor.opacity(0.12)
    }

    private var thumbnailForeground: Color {
        colorScheme == .dark
            ? Color(.ripeInk)
            : categoryColor
    }
}

// MARK: - Preview

#Preview("MonoThumbnail") {
    VStack(spacing: RipeSpacing.s4) {
        HStack(spacing: RipeSpacing.s3) {
            MonoThumbnail(label: "Amazon", categoryColor: Color(.ripeAccent))
            MonoThumbnail(label: "Ebay", categoryColor: Color(.ripeGood))
            MonoThumbnail(label: "Nike", categoryColor: Color(.ripeDanger))
            MonoThumbnail(label: "Sony", categoryColor: Color(.ripeWarn))
        }
        HStack(spacing: RipeSpacing.s3) {
            MonoThumbnail(label: "TV", categoryColor: Color(.ripeAccent), size: 56, round: true)
            MonoThumbnail(label: "Shoes", categoryColor: Color(.ripeGood), size: 40, round: false)
        }
        HStack(spacing: RipeSpacing.s3) {
            MonoThumbnail(
                label: "Cart",
                categoryColor: Color(.ripeAccent),
                systemImage: "cart.fill"
            )
            MonoThumbnail(
                label: "Tag",
                categoryColor: Color(.ripeGood),
                size: 56,
                round: true,
                systemImage: "tag.fill"
            )
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("MonoThumbnail Dark") {
    HStack(spacing: RipeSpacing.s3) {
        MonoThumbnail(label: "Amazon", categoryColor: Color(.ripeAccent))
        MonoThumbnail(label: "Ebay", categoryColor: Color(.ripeGood), round: true)
        MonoThumbnail(label: "T", categoryColor: Color(.ripeDanger), systemImage: "tag.fill")
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
