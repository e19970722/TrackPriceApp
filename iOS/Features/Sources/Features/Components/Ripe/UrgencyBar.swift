import SwiftUI

/// A horizontal progress bar indicating urgency by days remaining.
/// Color shifts from green (>7d) to accent (≤7d) to warn (≤3d).
/// Fill grows as days decrease — fuller bar = more urgent.
public struct UrgencyBar: View {
    let daysLeft: Int
    var width: CGFloat

    public init(daysLeft: Int, width: CGFloat = 52) {
        self.daysLeft = daysLeft
        self.width = width
    }

    // MARK: - Body

    public var body: some View {
        urgencyBarView
    }
}

// MARK: - Subviews

extension UrgencyBar {

    private var urgencyBarView: some View {
        ZStack(alignment: .leading) {
            barTrackView
            barFillView
        }
        .frame(width: width, height: 5)
    }

    private var barTrackView: some View {
        Capsule()
            .fill(Color(.ripeBarTrack))
            .frame(width: width, height: 5)
    }

    private var barFillView: some View {
        Capsule()
            .fill(fillColor)
            .frame(width: fillWidth, height: 5)
    }
}

// MARK: - Helpers

extension UrgencyBar {

    /// Fill = max(8%, 100% - min(100%, daysLeft * 1.4%)) of total width.
    private var fillWidth: CGFloat {
        let percentage = max(0.08, 1.0 - min(1.0, Double(daysLeft) * 0.014))
        return width * percentage
    }

    private var fillColor: Color {
        if daysLeft <= 3 {
            return Color(.ripeWarn)
        } else if daysLeft <= 7 {
            return Color(.ripeAccent)
        } else {
            return Color(.ripeGood)
        }
    }
}

// MARK: - Preview

#Preview("UrgencyBar") {
    VStack(alignment: .leading, spacing: RipeSpacing.s3) {
        HStack {
            Text("1 day left (warn)")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 1)
        }
        HStack {
            Text("3 days left (warn)")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 3)
        }
        HStack {
            Text("5 days left (accent)")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 5)
        }
        HStack {
            Text("7 days left (accent)")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 7)
        }
        HStack {
            Text("14 days left (good)")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 14)
        }
        HStack {
            Text("30 days left (good)")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 30)
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("UrgencyBar Dark") {
    VStack(alignment: .leading, spacing: RipeSpacing.s3) {
        HStack {
            Text("2 days")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 2)
        }
        HStack {
            Text("6 days")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 6)
        }
        HStack {
            Text("20 days")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            Spacer()
            UrgencyBar(daysLeft: 20)
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
