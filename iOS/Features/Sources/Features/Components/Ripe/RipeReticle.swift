import SwiftUI

/// Camera viewfinder corner brackets, overlaid absolutely on scan screen content.
/// Four L-shaped brackets mark the corners of the target area.
public struct RipeReticle: View {
    let size: CGFloat
    let color: Color

    public init(
        size: CGFloat = 188,
        color: Color = .white
    ) {
        self.size = size
        self.color = color
    }

    // MARK: - Body

    public var body: some View {
        reticleFrameView
    }
}

// MARK: - Subviews

extension RipeReticle {
    private var reticleFrameView: some View {
        ZStack {
            topLeadingBracket
            topTrailingBracket
            bottomLeadingBracket
            bottomTrailingBracket
        }
        .frame(width: size, height: size)
    }

    private var topLeadingBracket: some View {
        bracketShape(rotation: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var topTrailingBracket: some View {
        bracketShape(rotation: 90)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var bottomTrailingBracket: some View {
        bracketShape(rotation: 180)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private var bottomLeadingBracket: some View {
        bracketShape(rotation: 270)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private func bracketShape(rotation: Double) -> some View {
        BracketShape()
            .stroke(color.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 28 + 4, height: 28 + 4)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Bracket Shape

/// An L-shape path with a 4 pt corner radius on the outer corner, oriented top-left.
private struct BracketShape: Shape {
    func path(in _: CGRect) -> Path {
        let armLength: CGFloat = 28
        let cornerRadius: CGFloat = 4
        let thickness: CGFloat = 3

        var path = Path()
        // Outer corner with radius, top-left orientation
        // Start at end of horizontal arm
        path.move(to: CGPoint(x: armLength, y: thickness / 2))
        path.addLine(to: CGPoint(x: cornerRadius, y: thickness / 2))
        path.addQuadCurve(
            to: CGPoint(x: thickness / 2, y: cornerRadius),
            control: CGPoint(x: thickness / 2, y: thickness / 2)
        )
        path.addLine(to: CGPoint(x: thickness / 2, y: armLength))
        return path
    }
}

// MARK: - Preview

#Preview("RipeReticle") {
    ZStack {
        Color.black.ignoresSafeArea()
        RipeReticle()
    }
}

#Preview("RipeReticle — Custom size & color") {
    ZStack {
        Color.black.ignoresSafeArea()
        RipeReticle(size: 240, color: Color(.ripeAccent))
    }
}

#Preview("RipeReticle Dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        RipeReticle()
    }
    .preferredColorScheme(.dark)
}
