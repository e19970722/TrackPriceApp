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
    // MARK: - App

    public enum App {
        public static let tabHome = L10n.tr("app.tabHome", fallback: "Home")
        public static let tabTracks = L10n.tr("app.tabTracks", fallback: "Tracks")
        public static let tabProfile = L10n.tr("app.tabProfile", fallback: "Profile")
    }

    // MARK: - Auth

    public enum Auth {
        public static let appName = L10n.tr("auth.appName", fallback: "TrackPrice")
        public static let tagline = L10n.tr("auth.tagline", fallback: "Get notified when prices drop.")
        public static let signInWithGoogle = L10n.tr("auth.signInWithGoogle", fallback: "Sign in with Google")
    }

    // MARK: - Common

    public enum Common {
        public static let cancel = L10n.tr("common.cancel", fallback: "Cancel")
        public static let done = L10n.tr("common.done", fallback: "Done")
        public static let back = L10n.tr("common.back", fallback: "Back")
        public static let retry = L10n.tr("common.retry", fallback: "Retry")
    }

    // MARK: - Home

    public enum Home {
        public static let greeting = L10n.tr("home.greeting", fallback: "Good morning")
        public static let sectionOnTrend = L10n.tr("home.sectionOnTrend", fallback: "On Trend Tracks")
        public static let markets = L10n.tr("home.markets", fallback: "Markets")
        public static let sectionExpireSoon = L10n.tr("home.sectionExpireSoon", fallback: "Expire Soon")
        public static let seeAll = L10n.tr("home.seeAll", fallback: "See all")
        public static let sectionPriceTargets = L10n.tr("home.sectionPriceTargets", fallback: "Price Reach Targets")
        public static let shopNow = L10n.tr("home.shopNow", fallback: "Shop now")
    }

    // MARK: - TrackerList

    public enum TrackerList {
        public static let title = L10n.tr("trackerList.title", fallback: "Tracks")
        public static let deleteAction = L10n.tr("trackerList.deleteAction", fallback: "Delete")
        public static let errorMessage = L10n.tr("trackerList.errorMessage", fallback: "Failed to load trackers")
        public static let emptyTitle = L10n.tr("trackerList.emptyTitle", fallback: "No Trackers Yet")
        public static let emptyMessage = L10n.tr(
            "trackerList.emptyMessage",
            fallback: "Tap + to start tracking a price."
        )
    }

    // MARK: - TrackerDetail

    public enum TrackerDetail {
        public static let noData = L10n.tr("trackerDetail.noData", fallback: "—")
        public static func targetPrice(_ value: String) -> String {
            L10n.tr("trackerDetail.targetPrice", value, fallback: "Target: %@")
        }

        public static let priceHistory = L10n.tr("trackerDetail.priceHistory", fallback: "Price History")
        public static let noPriceHistory = L10n.tr("trackerDetail.noPriceHistory", fallback: "No price history yet")
        public static let target = L10n.tr("trackerDetail.target", fallback: "Target")
        public static let shopNow = L10n.tr("trackerDetail.shopNow", fallback: "Shop Now")
        public static let details = L10n.tr("trackerDetail.details", fallback: "Details")
        public static let statUrl = L10n.tr("trackerDetail.statUrl", fallback: "URL")
        public static let statCreated = L10n.tr("trackerDetail.statCreated", fallback: "Created")
        public static let statLastChecked = L10n.tr("trackerDetail.statLastChecked", fallback: "Last Checked")
        public static let lastCheckedNever = L10n.tr("trackerDetail.lastCheckedNever", fallback: "Never")
        public static let statNextCheck = L10n.tr("trackerDetail.statNextCheck", fallback: "Next Check")
    }

    // MARK: - AddTracker

    public enum AddTracker {
        public static let navTitleAdd = L10n.tr("addTracker.navTitleAdd", fallback: "Add Tracker")
        public static let navTitleBrowse = L10n.tr("addTracker.navTitleBrowse", fallback: "Browse")
        public static let navTitleConfirm = L10n.tr("addTracker.navTitleConfirm", fallback: "Confirm Element")
        public static let navTitleSetTarget = L10n.tr("addTracker.navTitleSetTarget", fallback: "Set Target")
        public static let urlPrompt = L10n.tr("addTracker.urlPrompt", fallback: "Enter a product URL")
        public static let urlPlaceholder = L10n.tr("addTracker.urlPlaceholder", fallback: "https://example.com/product")
        public static let goButton = L10n.tr("addTracker.goButton", fallback: "Go")
        public static let pasteFromClipboard = L10n.tr(
            "addTracker.pasteFromClipboard",
            fallback: "Paste from clipboard"
        )
        public static let confirmTitle = L10n.tr("addTracker.confirmTitle", fallback: "Is this the right element?")
        public static let selectedText = L10n.tr("addTracker.selectedText", fallback: "Selected text")
        public static func parsedPrice(_ value: String) -> String {
            L10n.tr("addTracker.parsedPrice", value, fallback: "Parsed price: %@")
        }

        public static let noPriceDetected = L10n.tr(
            "addTracker.noPriceDetected",
            fallback: "No price detected — you can enter it manually"
        )
        public static let looksCorrect = L10n.tr("addTracker.looksCorrect", fallback: "Looks correct")
        public static let reSelect = L10n.tr("addTracker.reSelect", fallback: "Re-select")
        public static let belowTarget = L10n.tr("addTracker.belowTarget", fallback: "Below target")
        public static let aboveTarget = L10n.tr("addTracker.aboveTarget", fallback: "Above target")
        public static let creating = L10n.tr("addTracker.creating", fallback: "Creating\u{2026}")
        public static let createTracker = L10n.tr("addTracker.createTracker", fallback: "Create Tracker")
    }

    // MARK: - Settings

    public enum Settings {
        public static let signOutConfirmTitle = L10n.tr(
            "settings.signOutConfirmTitle",
            fallback: "Sign out of TrackPrice?"
        )
        public static let signOutConfirmButton = L10n.tr("settings.signOutConfirmButton", fallback: "Sign Out")
        public static let sectionAccount = L10n.tr("settings.sectionAccount", fallback: "Account")
        public static let connectedAccounts = L10n.tr("settings.connectedAccounts", fallback: "Connected accounts")
        public static let defaultCurrency = L10n.tr("settings.defaultCurrency", fallback: "Default currency")
        public static let preferredStores = L10n.tr("settings.preferredStores", fallback: "Preferred stores")
        public static let plan = L10n.tr("settings.plan", fallback: "Plan")
        public static let sectionNotifications = L10n.tr("settings.sectionNotifications", fallback: "Notifications")
        public static let priceDrops = L10n.tr("settings.priceDrops", fallback: "Price drops")
        public static let expiringSoon = L10n.tr("settings.expiringSoon", fallback: "Expiring soon")
        public static let runningLow = L10n.tr("settings.runningLow", fallback: "Running low")
        public static let weeklyDigest = L10n.tr("settings.weeklyDigest", fallback: "Weekly digest")
        public static let sectionAbout = L10n.tr("settings.sectionAbout", fallback: "About")
        public static let helpAndFeedback = L10n.tr("settings.helpAndFeedback", fallback: "Help & feedback")
        public static let privacyPolicy = L10n.tr("settings.privacyPolicy", fallback: "Privacy policy")
        public static let signOutRow = L10n.tr("settings.signOutRow", fallback: "Sign out")
    }

    // MARK: - Expiry

    public enum Expiry {
        public static let firstPageTitle = L10n.tr("expiry.firstPageTitle", fallback: "Add to your kitchen")
        public static let firstPageDesc = L10n.tr(
            "expiry.firstPageDesc",
            fallback: "Scan a label and we'll read the best-before date — then nudge you before it turns."
        )
        public static let scanTheLabel = L10n.tr("expiry.scanTheLabel", fallback: "Scan the label")

        // ChooseMethodView
        public static let newItemNavTitle = L10n.tr("expiry.newItemNavTitle", fallback: "New Item")
        public static let enterManually = L10n.tr("expiry.enterManually", fallback: "Enter it myself")

        // ItemDetailView
        public static let navTitleEdit = L10n.tr("expiry.navTitleEdit", fallback: "Edit Item")
        public static let sectionUntilBestBefore = L10n.tr(
            "expiry.sectionUntilBestBefore",
            fallback: "UNTIL BEST BEFORE"
        )
        public static let days = L10n.tr("expiry.days", fallback: "days")
        public static let sectionFreshness = L10n.tr("expiry.sectionFreshness", fallback: "FRESHNESS")
        public static let statBestBefore = L10n.tr("expiry.statBestBefore", fallback: "Best before")
        public static let statAdded = L10n.tr("expiry.statAdded", fallback: "Added")
        public static let statReminderTitle = L10n.tr("expiry.statReminderTitle", fallback: "Reminder")
        public static func reminderDaysBefore(_ value: Int) -> String {
            L10n.tr("expiry.reminderDaysBefore", value, fallback: "%d days before")
        }

        public static let statLocation = L10n.tr("expiry.statLocation", fallback: "Location")
        public static let reminderSection = L10n.tr("expiry.reminderSection", fallback: "Reminder")
        public static let markingUsed = L10n.tr("expiry.markingUsed", fallback: "Marking\u{2026}")
        public static let markUsed = L10n.tr("expiry.markUsed", fallback: "Mark used")
        public static let fieldItemName = L10n.tr("expiry.fieldItemName", fallback: "Item name")
        public static let fieldStoredIn = L10n.tr("expiry.fieldStoredIn", fallback: "Stored in")
        public static let fieldQuantity = L10n.tr("expiry.fieldQuantity", fallback: "Quantity")
        public static let fieldBestBeforeDate = L10n.tr("expiry.fieldBestBeforeDate", fallback: "Best-before date")
        public static let navTitleSelectDate = L10n.tr("expiry.navTitleSelectDate", fallback: "Select date")

        // ItemDetailsView
        public static let navTitleItemDetails = L10n.tr("expiry.navTitleItemDetails", fallback: "Item details")
        public static let continueButton = L10n.tr("expiry.continueButton", fallback: "Continue")

        // ItemsView
        public static let listTitle = L10n.tr("expiry.listTitle", fallback: "Items")
        public static let listErrorMessage = L10n.tr("expiry.listErrorMessage", fallback: "Failed to load items")
        public static let listEmptyTitle = L10n.tr("expiry.listEmptyTitle", fallback: "No Items Yet")
        public static let listEmptyMessage = L10n.tr(
            "expiry.listEmptyMessage",
            fallback: "Tap + to track an expiry date."
        )

        // ReminderView
        public static let reminderNavTitle = L10n.tr("expiry.reminderNavTitle", fallback: "Reminder")
        public static func bestBefore(_ value: String) -> String {
            L10n.tr("expiry.bestBefore", value, fallback: "Best before %@")
        }

        public static let remindMe = L10n.tr("expiry.remindMe", fallback: "Remind me before it expires")
        public static let daysBefore = L10n.tr("expiry.daysBefore", fallback: "days before")
        public static let alsoAlertOnDay = L10n.tr("expiry.alsoAlertOnDay", fallback: "Also alert on the day")
        public static func morningOf(_ value: String) -> String {
            L10n.tr("expiry.morningOf", value, fallback: "Morning of %@")
        }

        public static let saving = L10n.tr("expiry.saving", fallback: "Saving\u{2026}")
        public static let saveItem = L10n.tr("expiry.saveItem", fallback: "Save item")

        // SavedView
        public static let savedAllSet = L10n.tr("expiry.savedAllSet", fallback: "All set")
        public static let viewItem = L10n.tr("expiry.viewItem", fallback: "View item")
        public static let addAnother = L10n.tr("expiry.addAnother", fallback: "Add another")

        // ScanLabelView
        public static let scanning = L10n.tr("expiry.scanning", fallback: "Looking for a date\u{2026}")
        public static let flash = L10n.tr("expiry.flash", fallback: "Flash")
        public static let flashOff = L10n.tr("expiry.flashOff", fallback: "Flash off")
    }
}

// MARK: - Implementation Details

public extension L10n {
    private static func tr(_ key: String, _ args: CVarArg..., fallback value: String) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: nil)
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
