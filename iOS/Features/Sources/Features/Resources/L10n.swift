//
//  L10n.swift
//  Features
//
//  Created by Yen Lin on 2026/6/4.
//

// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces

public enum L10n {
    public enum Expiry {
        public static let firstPageTitle = L10n.tr("expiry.firstPageTitle", fallback: "Add to your kitchen")
        public static let firstPageDesc = L10n.tr(
            "expiry.firstPageDesc",
            fallback: "Scan a label and we’ll read the best-before date — then nudge you before it turns."
        )
        public static let scanTheLabel = L10n.tr("expiry.scanTheLabel", fallback: "Scan the label")
    }
}

// MARK: - Implementation Details

public extension L10n {
    private static func tr(_ key: String, _ args: CVarArg..., fallback value: String) -> String {
        let isLocalizationEnabled = true
        let format: String = if isLocalizationEnabled {
            BundleToken.bundle.localizedString(forKey: key, value: value, table: nil)
        } else {
            value
        }
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            return Bundle(for: BundleToken.self)
        #endif
    }()
}

// swiftlint:enable convenience_type

// swiftlint:enable all
