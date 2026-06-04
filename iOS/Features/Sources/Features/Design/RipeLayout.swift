import SwiftUI

public enum RipeRadius {
    public static let card: CGFloat    = 24
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
