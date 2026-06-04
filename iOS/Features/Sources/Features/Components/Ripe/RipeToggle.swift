import SwiftUI

/// Custom pill on/off switch matching the Ripe design spec exactly.
/// Do not use SwiftUI's native Toggle — this matches the spec's 46×28 pill geometry.
public struct RipeToggle: View {
    let isOn: Bool
    let onToggle: () -> Void

    public init(isOn: Bool, onToggle: @escaping () -> Void) {
        self.isOn = isOn
        self.onToggle = onToggle
    }

    // MARK: - Body

    public var body: some View {
        togglePillView
            .onTapGesture {
                onToggle()
            }
    }
}

// MARK: - Subviews

extension RipeToggle {
    private var togglePillView: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            pillTrackView
            knobView
        }
        .frame(width: 46, height: 28)
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }

    private var pillTrackView: some View {
        Capsule()
            .fill(isOn ? Color(.ripeAccent) : Color(.ripeSurface2))
            .frame(width: 46, height: 28)
    }

    private var knobView: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 22, height: 22)
            .padding(.horizontal, 3)
    }
}

// MARK: - Preview

#Preview("RipeToggle") {
    VStack(spacing: RipeSpacing.s5) {
        HStack(spacing: RipeSpacing.s4) {
            Text("Off")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            RipeToggle(isOn: false, onToggle: {})
        }
        HStack(spacing: RipeSpacing.s4) {
            Text("On")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            RipeToggle(isOn: true, onToggle: {})
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeToggle Dark") {
    VStack(spacing: RipeSpacing.s5) {
        HStack(spacing: RipeSpacing.s4) {
            Text("Off")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            RipeToggle(isOn: false, onToggle: {})
        }
        HStack(spacing: RipeSpacing.s4) {
            Text("On")
                .font(RipeFont.label())
                .foregroundStyle(Color(.ripeInk2))
            RipeToggle(isOn: true, onToggle: {})
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
