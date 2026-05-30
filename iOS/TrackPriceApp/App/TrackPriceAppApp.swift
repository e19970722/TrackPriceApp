import Features
import SwiftUI

@main
struct TrackPriceAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        RipeFontRegistration.register()
    }

    var body: some Scene {
        WindowGroup {
            AppInitialView()
        }
    }
}
