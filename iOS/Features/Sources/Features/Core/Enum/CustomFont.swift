//
//  CustomFont.swift
//  Features
//
//  Created by Yen Lin on 2026/6/4.
//

import SwiftUI
import UIKit

public enum CustomFont {
    case display
    case title
    case heading
    case body
    case label
    case caption
    case num

    public var font: Font {
        switch self {
        case .display: CustomFont.display()
        case .title: CustomFont.title()
        case .heading: CustomFont.heading()
        case .body: CustomFont.body()
        case .label: CustomFont.label()
        case .caption: CustomFont.caption()
        case .num: CustomFont.num()
        }
    }

    public var uiFont: UIFont {
        switch self {
        case .display:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 30)
                ?? UIFont.systemFont(ofSize: 30, weight: .heavy)
        case .title:
            UIFont(name: "PlusJakartaSans-ExtraBold", size: 26)
                ?? UIFont.systemFont(ofSize: 26, weight: .heavy)
        case .heading:
            UIFont(name: "PlusJakartaSans-Bold", size: 19)
                ?? UIFont.systemFont(ofSize: 19, weight: .bold)
        case .body:
            UIFont(name: "PlusJakartaSans-SemiBold", size: 15)
                ?? UIFont.systemFont(ofSize: 15, weight: .semibold)
        case .label:
            UIFont(name: "PlusJakartaSans-SemiBold", size: 13)
                ?? UIFont.systemFont(ofSize: 13, weight: .semibold)
        case .caption:
            UIFont(name: "PlusJakartaSans-Medium", size: 12)
                ?? UIFont.systemFont(ofSize: 12, weight: .medium)
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

    static func title(_ size: CGFloat = 26) -> Font {
        .custom("PlusJakartaSans-ExtraBold", size: size)
    }

    static func heading(_ size: CGFloat = 19) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func label(_ size: CGFloat = 13) -> Font {
        .custom("PlusJakartaSans-SemiBold", size: size)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
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
