import SwiftUI

/// Floating action button sitting above the tab bar.
public struct RipeFab: View {
    let systemImage: String
    let action: () -> Void

    public init(
        systemImage: String = "plus",
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        fabButtonView
    }
}

// MARK: - Subviews

extension RipeFab {
    private var fabButtonView: some View {
        Button(action: action) {
            fabIconView
        }
        .buttonStyle(.plain)
        .shadow(
            color: Color(.ripeAccent).opacity(0.33),
            radius: 12,
            x: 0,
            y: 5
        )
    }

    private var fabIconView: some View {
        Image(systemName: systemImage)
            .iconFont(.fab)
            .foregroundStyle(Color(.ripeAccentInk))
            .frame(width: 58, height: 58)
            .background(
                Circle()
                    .fill(Color(.ripeAccent))
            )
    }
}

// MARK: - Preview

#Preview("RipeFab") {
    ZStack(alignment: .bottom) {
        Color(.ripeBg).ignoresSafeArea()
        RipeFab(action: {})
            .padding(.bottom, 90)
    }
}

#Preview("RipeFab — Custom icon") {
    ZStack(alignment: .bottom) {
        Color(.ripeBg).ignoresSafeArea()
        RipeFab(systemImage: "camera.fill", action: {})
            .padding(.bottom, 90)
    }
}

#Preview("RipeFab Dark") {
    ZStack(alignment: .bottom) {
        Color(.ripeBg).ignoresSafeArea()
        RipeFab(action: {})
            .padding(.bottom, 90)
    }
    .preferredColorScheme(.dark)
}
