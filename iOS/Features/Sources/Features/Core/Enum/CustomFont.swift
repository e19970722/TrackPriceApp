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
        case .display: RipeFont.display()
        case .title: RipeFont.title()
        case .heading: RipeFont.heading()
        case .body: RipeFont.body()
        case .label: RipeFont.label()
        case .caption: RipeFont.caption()
        case .num: RipeFont.num()
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

// MARK: - View Modifier

public extension View {
    func customFont(_ font: CustomFont) -> some View {
        self.font(font.font)
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
