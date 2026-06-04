import SwiftUI

/// The three root tabs of the app.
public enum RipeTab: CaseIterable {
    case home
    case tracks
    case profile
}

/// A frosted-glass bottom navigation bar matching the Ripe design spec.
/// The app currently uses SwiftUI's native `TabView`; this component is a
/// standalone, preview-able shell that can be adopted when a custom bar is needed.
public struct RipeTabBar: View {
    let active: RipeTab
    let onSelect: (RipeTab) -> Void

    public init(active: RipeTab, onSelect: @escaping (RipeTab) -> Void) {
        self.active = active
        self.onSelect = onSelect
    }

    // MARK: - Body

    public var body: some View {
        tabBarShellView
    }
}

// MARK: - Subviews

extension RipeTabBar {
    private var tabBarShellView: some View {
        VStack(spacing: 0) {
            topBorderLine
            tabBarContent
        }
        .background(frostedBackgroundView)
    }

    private var topBorderLine: some View {
        Rectangle()
            .fill(Color(.ripeLine))
            .frame(height: 1)
    }

    private var tabBarContent: some View {
        HStack(spacing: 0) {
            ForEach(RipeTab.allCases, id: \.self) { tab in
                tabItemButton(tab)
            }
        }
        .frame(height: 36)
        .padding(.bottom, 26)
    }

    private func tabItemButton(_ tab: RipeTab) -> some View {
        Button {
            onSelect(tab)
        } label: {
            tabItemLabel(tab)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func tabItemLabel(_ tab: RipeTab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: active == tab ? tab.filledSymbol : tab.outlineSymbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(active == tab ? Color(.ripeAccent) : Color(.ripeInk3))
        }
        .frame(height: 36)
    }

    private var frostedBackgroundView: some View {
        ZStack {
            Color(.ripeBg).opacity(0.86)
            Rectangle().fill(.ultraThinMaterial)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Helpers

private extension RipeTab {
    var outlineSymbol: String {
        switch self {
        case .home:    "house"
        case .tracks:  "tag"
        case .profile: "person"
        }
    }

    var filledSymbol: String {
        switch self {
        case .home:    "house.fill"
        case .tracks:  "tag.fill"
        case .profile: "person.fill"
        }
    }
}

// MARK: - Preview

#Preview("RipeTabBar") {
    ZStack(alignment: .bottom) {
        Color(.ripeBg).ignoresSafeArea()
        RipeTabBar(active: .home, onSelect: { _ in })
    }
}

#Preview("RipeTabBar — Tracks active") {
    ZStack(alignment: .bottom) {
        Color(.ripeBg).ignoresSafeArea()
        RipeTabBar(active: .tracks, onSelect: { _ in })
    }
}

#Preview("RipeTabBar Dark") {
    ZStack(alignment: .bottom) {
        Color(.ripeBg).ignoresSafeArea()
        RipeTabBar(active: .profile, onSelect: { _ in })
    }
    .preferredColorScheme(.dark)
}
