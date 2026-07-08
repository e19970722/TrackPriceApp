import SwiftUI

/// Display-only screen showing which provider the user signed in with.
/// No account linking — the badge marks the single actual provider.
struct ConnectedAccountsView: View {
    let provider: String // "apple" or "google"
    let email: String?

    // MARK: - Body

    var body: some View {
        contentScrollView
            .background(Color(.ripeBg).ignoresSafeArea())
            .navigationTitle(L10n.Settings.connectedAccounts)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

extension ConnectedAccountsView {
    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s3) {
                providersCardView
                footerLabel
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s6)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    private var providersCardView: some View {
        RipeCard(padding: 0) {
            VStack(spacing: 0) {
                providerRow(
                    name: "Apple",
                    icon: "apple.logo",
                    isConnected: provider == "apple",
                    isLast: false
                )
                providerRow(
                    name: "Google",
                    icon: "globe",
                    isConnected: provider == "google",
                    isLast: true
                )
            }
        }
    }

    private var footerLabel: some View {
        Text(L10n.Settings.connectedAccountsFooter)
            .customFont(.medium12)
            .foregroundStyle(Color(.ripeInk2))
            .padding(.horizontal, RipeSpacing.s4)
    }

    private var connectedBadgeView: some View {
        Text(L10n.Settings.connectedBadge)
            .customFont(.semibold12)
            .foregroundStyle(Color(.ripeGood))
            .padding(.horizontal, RipeSpacing.s3)
            .padding(.vertical, RipeSpacing.s1)
            .background(Capsule().fill(Color(.ripeGood).opacity(0.12)))
    }

    private func providerRow(name: String, icon: String, isConnected: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: RipeSpacing.s3) {
                iconTileView(systemName: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .customFont(.semibold15)
                        .foregroundStyle(Color(.ripeInk))
                    if isConnected, let email {
                        Text(email)
                            .customFont(.medium12)
                            .foregroundStyle(Color(.ripeInk2))
                    }
                }
                Spacer()
                if isConnected {
                    connectedBadgeView
                }
            }
            .padding(.horizontal, RipeSpacing.s4)
            .padding(.vertical, RipeSpacing.s3)

            if !isLast {
                Color(.ripeLine)
                    .frame(height: 1)
                    .padding(.leading, RipeSpacing.s4 + 36 + RipeSpacing.s3)
            }
        }
    }

    private func iconTileView(systemName: String) -> some View {
        Image(systemName: systemName)
            .iconFont(.md)
            .foregroundStyle(Color(.ripeInk))
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous)
                    .fill(Color(.ripeInk).opacity(0.06))
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConnectedAccountsView(provider: "apple", email: "sam@rivers.me")
    }
}
