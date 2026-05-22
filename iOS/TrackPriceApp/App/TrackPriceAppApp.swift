import Features
import SwiftUI

@main
struct TrackPriceAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppInitialView()
        }
    }
}
