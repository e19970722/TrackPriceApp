import SwiftUI

/// A subtle 45° repeating diagonal-stripe texture, drawn with `Canvas`.
///
/// Used as an overlay on tinted tiles (illustration tiles, thumbnails) to add a
/// soft, premium texture. The stripe colour and opacity are caller-controlled so
/// it can render light-on-dark or dark-on-light depending on the surface.
///
/// Generic component — it must NOT add `WithPerceptionTracking`; that is the
/// caller's responsibility.
public struct DiagonalStripes: View {
    private let color: Color
    private let stripeWidth: CGFloat
    private let gap: CGFloat

    public init(
        color: Color,
        stripeWidth: CGFloat = 3,
        gap: CGFloat = 5
    ) {
        self.color = color
        self.stripeWidth = stripeWidth
        self.gap = gap
    }

    // MARK: - Body

    public var body: some View {
        stripeCanvas
    }
}

// MARK: - Subviews

extension DiagonalStripes {
    private var stripeCanvas: some View {
        Canvas { context, size in
            let step = stripeWidth + gap
            let diag = sqrt(size.width * size.width + size.height * size.height)
            var offset: CGFloat = -diag
            while offset < diag * 2 {
                context.fill(stripePath(at: offset, diag: diag), with: .color(color))
                offset += step
            }
        }
    }

    private func stripePath(at offset: CGFloat, diag: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: offset + diag, y: diag))
            path.addLine(to: CGPoint(x: offset + diag + stripeWidth, y: diag))
            path.addLine(to: CGPoint(x: offset + stripeWidth, y: 0))
            path.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview {
    DiagonalStripes(color: .black.opacity(0.05))
        .frame(width: 96, height: 96)
        .background(Color(.ripeAccentSoft))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding()
        .background(Color(.ripeBg))
}
