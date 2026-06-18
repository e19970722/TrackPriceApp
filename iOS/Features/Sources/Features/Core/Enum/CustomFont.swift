//
//  CustomFont.swift
//  Features
//
//  Created by Yen Lin on 2026/6/4.
//

import SwiftUI
import UIKit

public enum CustomFont {
    // ExtraBold
    case extrabold10
    case extrabold22
    case extrabold26
    case extrabold30
    case extrabold34
    case extrabold40
    case extrabold44

    // Bold
    case bold12
    case bold13
    case bold15
    case bold17
    case bold18
    case bold19
    case bold22

    // SemiBold
    case semibold12
    case semibold13
    case semibold15
    case semibold17
    case semibold18

    // Medium
    case medium10
    case medium11
    case medium12
    case medium13
    case medium15

    /// Regular
    case regular12

    private static let family = "PlusJakartaSans"

    private enum Weight: String {
        case extraBold = "ExtraBold"
        case bold = "Bold"
        case semiBold = "SemiBold"
        case medium = "Medium"
        case regular = "Regular"

        var uiFontWeight: UIFont.Weight {
            switch self {
            case .extraBold: .heavy
            case .bold: .bold
            case .semiBold: .semibold
            case .medium: .medium
            case .regular: .regular
            }
        }
    }

    private var spec: (weight: Weight, size: CGFloat) {
        switch self {
        case .extrabold10: (.extraBold, 10)
        case .extrabold22: (.extraBold, 22)
        case .extrabold26: (.extraBold, 26)
        case .extrabold30: (.extraBold, 30)
        case .extrabold34: (.extraBold, 34)
        case .extrabold40: (.extraBold, 40)
        case .extrabold44: (.extraBold, 44)
        case .bold12: (.bold, 12)
        case .bold13: (.bold, 13)
        case .bold15: (.bold, 15)
        case .bold17: (.bold, 17)
        case .bold18: (.bold, 18)
        case .bold19: (.bold, 19)
        case .bold22: (.bold, 22)
        case .semibold12: (.semiBold, 12)
        case .semibold13: (.semiBold, 13)
        case .semibold15: (.semiBold, 15)
        case .semibold17: (.semiBold, 17)
        case .semibold18: (.semiBold, 18)
        case .medium10: (.medium, 10)
        case .medium11: (.medium, 11)
        case .medium12: (.medium, 12)
        case .medium13: (.medium, 13)
        case .medium15: (.medium, 15)
        case .regular12: (.regular, 12)
        }
    }

    private var fontName: String {
        "\(Self.family)-\(spec.weight.rawValue)"
    }

    public var font: Font {
        .custom(fontName, size: spec.size)
    }

    public var uiFont: UIFont {
        UIFont(name: fontName, size: spec.size)
            ?? UIFont.systemFont(ofSize: spec.size, weight: spec.weight.uiFontWeight)
    }
}

// MARK: - View Modifier

public extension View {
    func customFont(_ font: CustomFont) -> some View {
        self.font(font.font)
    }

    func ripeDisplayTracking() -> some View {
        tracking(-0.02 * 16) // approx -0.02em at base size
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        Text("ExtraBold 30 — Price Tracker").customFont(.extrabold30)
        Text("ExtraBold 26 — My Trackers").customFont(.extrabold26)
        Text("Bold 19 — Recent Items").customFont(.bold19)
        Text("SemiBold 15 — Track any price online").customFont(.semibold15)
        Text("SemiBold 13 — Last checked 2h ago").customFont(.semibold13)
        Text("Medium 12 — Expires 2026-12-31").customFont(.medium12)
        Text("Bold 17 mono — $1,299.00").customFont(.bold17).monospacedDigit()
    }
    .padding()
}
