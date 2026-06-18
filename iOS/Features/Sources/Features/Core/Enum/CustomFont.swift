//
//  CustomFont.swift
//  Features
//
//  Created by Yen Lin on 2026/6/4.
//

import SwiftUI
import UIKit

public enum CustomFont {
    // Display & Title
    case display
    case displayLg
    case displayXL
    case title
    case title2
    case priceHero

    // Headings
    case heading
    case headingLg
    case subheading

    // Body
    case body
    case bodyLg
    case headline
    case subheadline

    // Label & Caption
    case label
    case labelLg
    case caption
    case captionSm
    case caption2
    case footnote

    /// Numeric
    case num

    public var font: Font {
        switch self {
        case .display: CustomFont.display()
        case .displayLg: CustomFont.displayLg()
        case .displayXL: CustomFont.displayXL()
        case .title: CustomFont.title()
        case .title2: CustomFont.title2()
        case .priceHero: CustomFont.priceHero()
        case .heading: CustomFont.heading()
        case .headingLg: CustomFont.headingLg()
        case .subheading: CustomFont.subheading()
        case .body: CustomFont.body()
        case .bodyLg: CustomFont.bodyLg()
        case .headline: CustomFont.headline()
        case .subheadline: CustomFont.subheadline()
        case .label: CustomFont.label()
        case .labelLg: CustomFont.labelLg()
        case .caption: CustomFont.caption()
        case .captionSm: CustomFont.captionSm()
        case .caption2: CustomFont.caption2()
        case .footnote: CustomFont.footnote()
        case .num: CustomFont.num()
        }
    }

    /// Returns this font family at a custom size. Use sparingly — prefer a dedicated case
    /// for any size that recurs in the design system.
    public func font(size: CGFloat) -> Font {
        switch self {
        case .display, .displayLg, .displayXL: CustomFont.display(size)
        case .title, .title2: CustomFont.title(size)
        case .priceHero: CustomFont.priceHero(size)
        case .heading, .headingLg, .subheading: CustomFont.heading(size)
        case .body, .bodyLg, .headline, .subheadline: CustomFont.body(size)
        case .label, .labelLg: CustomFont.label(size)
        case .caption, .captionSm, .caption2, .footnote: CustomFont.caption(size)
        case .num: CustomFont.num(size)
        }
    }

    public var uiFont: UIFont {
        switch self {
        case .display:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 30)
                ?? UIFont.systemFont(ofSize: 30, weight: .heavy)
        case .displayLg:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 34)
                ?? UIFont.systemFont(ofSize: 34, weight: .heavy)
        case .displayXL:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 44)
                ?? UIFont.systemFont(ofSize: 44, weight: .heavy)
        case .title:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 26)
                ?? UIFont.systemFont(ofSize: 26, weight: .heavy)
        case .title2:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 22)
                ?? UIFont.systemFont(ofSize: 22, weight: .heavy)
        case .priceHero:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 40)
                ?? UIFont.systemFont(ofSize: 40, weight: .heavy)
        case .heading:
            UIFont(name: "PlusJakartaSans-Bold", size: 19)
                ?? UIFont.systemFont(ofSize: 19, weight: .bold)
        case .headingLg:
            UIFont(name: "PlusJakartaSans-Bold", size: 22)
                ?? UIFont.systemFont(ofSize: 22, weight: .bold)
        case .subheading:
            UIFont(name: "PlusJakartaSans-Bold", size: 17)
                ?? UIFont.systemFont(ofSize: 17, weight: .bold)
        case .body:
            UIFont(name: "PlusJakartaSans-SemiBold", size: 15)
                ?? UIFont.systemFont(ofSize: 15, weight: .semibold)
        case .bodyLg:
            UIFont(name: "PlusJakartaSans-SemiBold", size: 18)
                ?? UIFont.systemFont(ofSize: 18, weight: .semibold)
        case .headline:
            UIFont(name: "PlusJakartaSans-Bold", size: 17)
                ?? UIFont.systemFont(ofSize: 17, weight: .bold)
        case .subheadline:
            UIFont(name: "PlusJakartaSans-Medium", size: 15)
                ?? UIFont.systemFont(ofSize: 15, weight: .medium)
        case .label:
            UIFont(name: "PlusJakartaSans-SemiBold", size: 13)
                ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        case .labelLg:
            UIFont(name: "PlusJakartaSans-SemiBold", size: 17)
                ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        case .caption:
            UIFont(name: "PlusJakartaSans-Medium", size: 12)
                ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        case .captionSm:
            UIFont(name: "PlusJakartaSans-Medium", size: 11)
                ?? UIFont.systemFont(ofSize: 11, weight: .medium)
        case .caption2:
            UIFont(name: "PlusJakartaSans-Medium", size: 10)
                ?? UIFont.systemFont(ofSize: 10, weight: .medium)
        case .footnote:
            UIFont(name: "PlusJakartaSans-Medium", size: 13)
                ?? UIFont.systemFont(ofSize: 13, weight: .medium)
        case .num:
            UIFont(name: "PlusJakartaSans-Bold", size: 17)
                ?? UIFont.systemFont(ofSize: 17, weight: .bold)
        }
    }
}

// MARK: - Static Font Functions

public extension CustomFont {
    static func display(_ size: CGFloat = 30) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func displayLg(_ size: CGFloat = 34) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func displayXL(_ size: CGFloat = 44) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func title(_ size: CGFloat = 26) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func title2(_ size: CGFloat = 22) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func priceHero(_ size: CGFloat = 40) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func heading(_ size: CGFloat = 19) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }

    static func headingLg(_ size: CGFloat = 22) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }

    static func subheading(_ size: CGFloat = 17) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func bodyLg(_ size: CGFloat = 18) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func headline(_ size: CGFloat = 17) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }

    static func subheadline(_ size: CGFloat = 15) -> Font {
        .custom("PlusJakartaSans-Medium", size: size)
    }

    static func label(_ size: CGFloat = 13) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func labelLg(_ size: CGFloat = 17) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .custom("PlusJakartaSans-Medium", size: size)
    }

    static func captionSm(_ size: CGFloat = 11) -> Font {
        .custom("PlusJakartaSans-Medium", size: size)
    }

    static func caption2(_ size: CGFloat = 10) -> Font {
        .custom("PlusJakartaSans-Medium", size: size)
    }

    static func footnote(_ size: CGFloat = 13) -> Font {
        .custom("PlusJakartaSans-Medium", size: size)
    }

    static func num(_ size: CGFloat = 17) -> Font {
        .custom("PlusJakartaSans-Bold", size: size).monospacedDigit()
    }
}

// MARK: - View Modifier

public extension View {
    func customFont(_ font: CustomFont) -> some View {
        self.font(font.font)
    }

    /// Apply a `CustomFont` family at a custom size. Prefer the no-size overload when possible;
    /// reach for this only when the size is dynamic at runtime or a one-off in a design.
    func customFont(_ font: CustomFont, size: CGFloat) -> some View {
        self.font(font.font(size: size))
    }

    func ripeDisplayTracking() -> some View {
        tracking(-0.02 * 16) // approx -0.02em at base size
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        Text("Display — Price Tracker").customFont(.display)
        Text("Title — My Trackers").customFont(.title)
        Text("Heading — Recent Items").customFont(.heading)
        Text("Body — Track any price online").customFont(.body)
        Text("Label — Last checked 2h ago").customFont(.label)
        Text("Caption — Expires 2026-12-31").customFont(.caption)
        Text("Num — $1,299.00").customFont(.num)
    }
    .padding()
}
