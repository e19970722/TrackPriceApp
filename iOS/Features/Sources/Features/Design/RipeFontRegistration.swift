import CoreText
import Foundation

/// Registers Plus Jakarta Sans with Core Text so `Font.custom("PlusJakartaSans-…")`
/// resolves instead of silently falling back to the system font.
///
/// SPM places the .ttf files in `Bundle.module` but doesn't register them — without
/// this step, `Font.custom` returns SF Pro and display weights look thin.
public enum RipeFontRegistration {
    private static let names = [
        "PlusJakartaSans-Regular",
        "PlusJakartaSans-Medium",
        "PlusJakartaSans-SemiBold",
        "PlusJakartaSans-Bold",
        "PlusJakartaSans-ExtraBold",
    ]

    private static let registerOnce: Void = {
        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    public static func register() {
        _ = registerOnce
    }
}
