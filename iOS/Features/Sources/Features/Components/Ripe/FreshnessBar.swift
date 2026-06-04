import SwiftUI

/// Full-width shelf-life timeline for item detail screens.
/// Distinct from `UrgencyBar` which is a compact list-row indicator.
public struct FreshnessBar: View {
    let addedDate: Date
    let expiryDate: Date
    let today: Date

    public init(
        addedDate: Date,
        expiryDate: Date,
        today: Date = .now
    ) {
        self.addedDate = addedDate
        self.expiryDate = expiryDate
        self.today = today
    }

    // MARK: - Body

    public var body: some View {
        freshnessContainerView
    }
}

// MARK: - Subviews

extension FreshnessBar {
    private var freshnessContainerView: some View {
        VStack(spacing: 6) {
            trackView
            dateLabelsRow
        }
    }

    private var trackView: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                gradientTrackView
                elapsedOverlayView(trackWidth: width)
                todayMarkerView(trackWidth: width)
            }
        }
        .frame(height: 14)
    }

    private var gradientTrackView: some View {
        Capsule()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(.ripeGood), location: 0.0),
                        .init(color: Color(.ripeWarn), location: 0.74),
                        .init(color: Color(.ripeDanger), location: 1.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private func elapsedOverlayView(trackWidth: CGFloat) -> some View {
        Capsule()
            .fill(Color(.ripeBg).opacity(0.55))
            .frame(width: trackWidth * (1 - elapsedFraction), height: 14)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func todayMarkerView(trackWidth: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .overlay(
                Circle()
                    .strokeBorder(Color(.ripeInk), lineWidth: 3)
            )
            .frame(width: 18, height: 18)
            .offset(x: markerOffset(trackWidth: trackWidth))
    }

    private var dateLabelsRow: some View {
        HStack {
            startDateLabel
            Spacer()
            endDateLabel
        }
    }

    private var startDateLabel: some View {
        Text(addedDate, style: .date)
            .font(CustomFont.caption(11.5))
            .foregroundStyle(Color(.ripeInk3))
    }

    private var endDateLabel: some View {
        Text(expiryDate, style: .date)
            .font(CustomFont.caption(11.5))
            .foregroundStyle(Color(.ripeInk3))
    }
}

// MARK: - Helpers

extension FreshnessBar {
    /// Fraction [0, 1] of the total shelf life that has elapsed.
    private var elapsedFraction: CGFloat {
        let total = expiryDate.timeIntervalSince(addedDate)
        guard total > 0 else { return 1 }
        let elapsed = today.timeIntervalSince(addedDate)
        return min(1, max(0, elapsed / total))
    }

    /// X offset for the today marker, centred on the elapsed fraction position.
    private func markerOffset(trackWidth: CGFloat) -> CGFloat {
        // Centre the 18-pt circle on the fraction point; clamp to stay on track
        let rawX = trackWidth * elapsedFraction - 9
        return min(trackWidth - 18, max(0, rawX))
    }
}

// MARK: - Preview

#Preview("FreshnessBar — Fresh") {
    let calendar = Calendar.current
    let added = calendar.date(byAdding: .day, value: -5, to: .now)!
    let expiry = calendar.date(byAdding: .day, value: 25, to: .now)!
    return FreshnessBar(addedDate: added, expiryDate: expiry)
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
}

#Preview("FreshnessBar — Near expiry") {
    let calendar = Calendar.current
    let added = calendar.date(byAdding: .day, value: -20, to: .now)!
    let expiry = calendar.date(byAdding: .day, value: 3, to: .now)!
    return FreshnessBar(addedDate: added, expiryDate: expiry)
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
}

#Preview("FreshnessBar — Expired") {
    let calendar = Calendar.current
    let added = calendar.date(byAdding: .day, value: -30, to: .now)!
    let expiry = calendar.date(byAdding: .day, value: -2, to: .now)!
    return FreshnessBar(addedDate: added, expiryDate: expiry)
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
}

#Preview("FreshnessBar Dark") {
    let calendar = Calendar.current
    let added = calendar.date(byAdding: .day, value: -7, to: .now)!
    let expiry = calendar.date(byAdding: .day, value: 14, to: .now)!
    return FreshnessBar(addedDate: added, expiryDate: expiry)
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
        .preferredColorScheme(.dark)
}
