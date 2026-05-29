import SwiftUI

public enum RipeFont {
    public static func display(_ size: CGFloat = 30) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }
    public static func title(_ size: CGFloat = 26) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }
    public static func heading(_ size: CGFloat = 19) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }
    public static func body(_ size: CGFloat = 15) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }
    public static func label(_ size: CGFloat = 13) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }
    public static func caption(_ size: CGFloat = 12) -> Font {
        .custom("PlusJakartaSans-Medium", size: size)
    }
    public static func num(_ size: CGFloat = 17) -> Font {
        .custom("PlusJakartaSans-Bold", size: size).monospacedDigit()
    }
}

// Convenience View modifier for tight display tracking
public extension View {
    func ripeDisplayTracking() -> some View {
        self.tracking(-0.02 * 16) // approx -0.02em at base size
    }
}
