import ComposableArchitecture
import Foundation
import UserNotifications

public struct NotificationClient {
    public var requestPermission: @Sendable () async -> Bool
}

extension NotificationClient: DependencyKey {
    public static var liveValue: NotificationClient {
        NotificationClient(
            requestPermission: {
                let center = UNUserNotificationCenter.current()
                return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            }
        )
    }
    public static var testValue: NotificationClient {
        NotificationClient(requestPermission: { true })
    }
}

extension DependencyValues {
    public var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}
