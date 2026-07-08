@testable import Features
import Testing

@Suite("RipeToast")
struct RipeToastTests {
    /// The auto-dismiss behaviour was confirmed with the user as "always close after
    /// 3 seconds". This pins that contract so the timing can't silently drift.
    @Test("Auto-dismiss duration is 3 seconds")
    func autoDismissDurationIsThreeSeconds() {
        #expect(RipeToast.autoDismissDuration == .seconds(3))
    }
}
