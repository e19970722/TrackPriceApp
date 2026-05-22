import ComposableArchitecture
import Foundation
import UIKit
import UserNotifications

public struct NotificationClient {
    public var requestPermission: @Sendable () async -> Bool
    public var registerForRemoteNotifications: @Sendable () async -> Void
    public var getDeviceToken: @Sendable () async -> String?
}

extension NotificationClient: DependencyKey {
    public static var liveValue: NotificationClient {
        NotificationClient(
            requestPermission: {
                let center = UNUserNotificationCenter.current()
                return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            },
            registerForRemoteNotifications: {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            },
            getDeviceToken: {
                UserDefaults.standard.string(forKey: "apns_device_token")
            }
        )
    }

    public static var testValue: NotificationClient {
        NotificationClient(
            requestPermission: { true },
            registerForRemoteNotifications: { },
            getDeviceToken: { "test-device-token" }
        )
    }
}

extension DependencyValues {
    public var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}
