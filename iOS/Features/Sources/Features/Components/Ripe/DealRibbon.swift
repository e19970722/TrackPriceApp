import SwiftUI

/// Diagonal "DEAL" corner badge for price cards.
/// Caller must set `.clipped()` (or `.clipShape`) on the parent container
/// to crop the overflow of the ribbon outside the card bounds.
public struct DealRibbon: View {
    public init() {}

    // MARK: - Body

    public var body: some View {
        ribbonCornerView
    }
}

// MARK: - Subviews

extension DealRibbon {
    private var ribbonCornerView: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ribbonBannerView
        }
        .frame(width: 66, height: 66)
        .clipped()
    }

    private var ribbonBannerView: some View {
        Text("DEAL")
            .font(.system(size: 10, weight: .black))
            .tracking(0.6)
            .foregroundStyle(Color.white)
            .frame(width: 92)
            .padding(.vertical, 4)
            .background(Color(.ripeGood))
            .rotationEffect(.degrees(-45), anchor: .center)
            .offset(x: -22, y: 13)
    }
}

// MARK: - Preview

#Preview("DealRibbon") {
    HStack(spacing: RipeSpacing.s4) {
        // Embedded in a card to show clipping
        RipeCard(padding: 0) {
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                    Text("Nike Air Max 90")
                        .font(RipeFont.heading(15))
                        .foregroundStyle(Color(.ripeInk))
                    Text("$89.99")
                        .font(RipeFont.num(20))
                        .foregroundStyle(Color(.ripeGood))
                }
                .padding(RipeSpacing.s4)

                DealRibbon()
            }
            .clipped()
        }

        // Standalone ribbon preview
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
                .fill(Color(.ripeSurface2))
                .frame(width: 120, height: 80)
            DealRibbon()
        }
        .clipped()
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("DealRibbon Dark") {
    ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
            .fill(Color(.ripeSurface))
            .frame(width: 140, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
                    .strokeBorder(Color(.ripeLine), lineWidth: 1)
            )
        DealRibbon()
    }
    .clipped()
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
