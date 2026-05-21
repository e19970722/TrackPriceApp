import ComposableArchitecture
import Foundation
import UserNotifications

struct NotificationClient {
    var requestPermission: @Sendable () async -> Bool
}

extension NotificationClient: DependencyKey {
    static var liveValue: NotificationClient {
        NotificationClient(
            requestPermission: {
                let center = UNUserNotificationCenter.current()
                return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            }
        )
    }
    static var testValue: NotificationClient {
        NotificationClient(requestPermission: { true })
    }
}

extension DependencyValues {
    var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}
