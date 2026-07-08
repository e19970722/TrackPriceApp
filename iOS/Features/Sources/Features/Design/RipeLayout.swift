import SwiftUI

public enum RipeRadius {
    public static let card: CGFloat    = 24
    public static let sm: CGFloat      = 14
    public static let control: CGFloat = 14
    public static let pill: CGFloat    = 999
    public static let xs: CGFloat      = 10
}

public enum RipeSpacing {
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20  // screen gutter
    public static let s6: CGFloat = 24
    public static let s7: CGFloat = 32
}

public enum RipeSectionEmpty {
    public static let gap: CGFloat               = 14
    public static let horizontalPadding: CGFloat = 18
    public static let tileSize: CGFloat          = 48
    public static let tileRadius: CGFloat        = 14
    public static let iconSize: CGFloat          = 22
    public static let lineSpacing: CGFloat       = 6 // ~1.45 line height at 13.5pt
    public static let defaultHeight: CGFloat     = 92
    public static let trendHeight: CGFloat       = 84
}

public enum RipeEmptyStateLayout {
    /// Side length of the square illustration tile.
    public static let tileSize: CGFloat = 96
    /// Corner radius of the illustration tile.
    public static let tileRadius: CGFloat = 28
    /// SF Symbol point size for the centered icon.
    public static let iconSize: CGFloat = 40
    /// Max width of the body copy before it wraps.
    public static let bodyMaxWidth: CGFloat = 260
    /// Line spacing applied to the multiline body copy (~1.5 line height at 15pt).
    public static let bodyLineSpacing: CGFloat = 6
    /// Vertical gap between the tile, title and body block.
    public static let verticalSpacing: CGFloat = 16
    /// Vertical gap between the title and body copy.
    public static let textSpacing: CGFloat = 8
    /// Minimum height the empty state occupies inside a list row.
    public static let minHeight: CGFloat = 320
}

public struct RipeShadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public static let card = RipeShadow(
        color: Color(red: 0.275, green: 0.204, blue: 0.118).opacity(0.09),
        radius: 14, x: 0, y: 10
    )
    public static let soft = RipeShadow(
        color: Color(red: 0.275, green: 0.204, blue: 0.118).opacity(0.05),
        radius: 5, x: 0, y: 2
    )
}

public extension View {
    func ripeShadow(_ shadow: RipeShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
