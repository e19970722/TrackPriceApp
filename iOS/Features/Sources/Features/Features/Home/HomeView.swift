import SwiftUI

public struct HomeView: View {

    public init() {}

    // MARK: - Body

    public var body: some View {
        ZStack {
            Color(.ripeBg)
                .ignoresSafeArea()
            placeholderLabel
        }
    }
}

// MARK: - Subviews

extension HomeView {

    private var placeholderLabel: some View {
        Text("Home")
            .font(.title2)
            .foregroundStyle(Color(.ripeInk3))
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
