import ComposableArchitecture
import SwiftUI

public struct SettingsView: View {
    @Perception.Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                settingsContentView
            }
        }
    }
}

// MARK: - Subviews

extension SettingsView {
    private var settingsContentView: some View {
        scrollContentView
            .background(Color(.ripeBg).ignoresSafeArea())
            .task {
                await store.send(.task).finish()
            }
            .navigationDestination(
                item: $store.destination.sending(\.destinationChanged),
                destination: destinationView
            )
            .sheet(isPresented: $store.isMailComposerPresented.sending(\.mailComposerPresented)) {
                mailComposerSheetView
            }
            .sheet(isPresented: $store.isSafariPresented.sending(\.safariPresented)) {
                safariSheetView
            }
            .alert(
                L10n.Settings.signOutConfirmTitle,
                isPresented: $store.isSignOutConfirmationPresented.sending(\.signOutConfirmationPresented)
            ) {
                signOutDialogButtons
            }
            .overlay(alignment: .bottom) { errorToastView }
    }

    private var errorToastView: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                if let message = store.errorMessage {
                    RipeToast(
                        message: message,
                        onDismiss: { store.send(.errorToastDismissed) },
                        onRetry: { store.send(.errorToastRetryTapped) }
                    )
                    .padding(.horizontal, RipeSpacing.s5)
                    .padding(.bottom, RipeSpacing.s4)
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(
                        scale: 0.9,
                        anchor: .bottom
                    )))
                }
            }
            .animation(
                .spring(response: 0.35, dampingFraction: 0.7),
                value: store.errorMessage != nil
            )
        }
    }

    private var scrollContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s6) {
                profileHeaderView
                accountSectionView
                notificationsSectionView
                aboutSectionView
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s6)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    private func destinationView(_ destination: SettingsFeature.Destination) -> some View {
        WithPerceptionTracking {
            switch destination {
            case .connectedAccounts:
                ConnectedAccountsView(provider: store.user?.authProvider ?? "", email: store.user?.email)
            case .plan:
                PlanView(tier: store.user?.subscriptionTier ?? "free")
            }
        }
    }

    private var mailComposerSheetView: some View {
        MailComposerView(
            recipient: Config.supportEmail,
            subject: L10n.Settings.feedbackMailSubject
        ) {
            store.send(.mailComposerPresented(false))
        }
    }

    private var safariSheetView: some View {
        SafariView(url: Config.privacyPolicyURL)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var signOutDialogButtons: some View {
        Button(L10n.Settings.signOutConfirmButton, role: .destructive) {
            store.send(.signOutConfirmed)
        }
        Button(L10n.Common.cancel, role: .cancel) {
            store.send(.signOutCancelled)
        }
    }

    private var profileHeaderView: some View {
        HStack(spacing: RipeSpacing.s4) {
            MonoThumbnail(
                label: userInitials,
                categoryColor: Color(.ripeAccent),
                size: 64,
                round: true
            )
            VStack(alignment: .leading, spacing: RipeSpacing.s1) {
                Text(displayName)
                    .customFont(.extrabold26)
                    .foregroundStyle(Color(.ripeInk))
                if let email = store.user?.email {
                    Text(email)
                        .customFont(.medium13)
                        .foregroundStyle(Color(.ripeInk3))
                }
            }
            Spacer()
        }
    }

    private var accountSectionView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            SectionLabel(title: L10n.Settings.sectionAccount)
            RipeCard(padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "creditcard",
                        iconColor: Color(.ripeCat5),
                        title: L10n.Settings.connectedAccounts,
                        value: providerDisplayName,
                        isLast: false
                    ) {
                        store.send(.rowTapped(.connectedAccounts))
                    }
                    settingsRow(
                        icon: "sparkles",
                        iconColor: Color(.ripeAccent),
                        title: L10n.Settings.plan,
                        value: planDisplayName,
                        isLast: true
                    ) {
                        store.send(.rowTapped(.plan))
                    }
                }
            }
        }
    }

    private var notificationsSectionView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            SectionLabel(title: L10n.Settings.sectionNotifications)
            RipeCard(padding: 0) {
                VStack(spacing: 0) {
                    notificationToggleRow(
                        icon: "tag",
                        iconColor: Color(.ripeCat1),
                        title: L10n.Settings.priceDrops,
                        detail: "When a track hits target",
                        isOn: $store.preferences.sending(\.preferenceToggled).priceDrops,
                        isLast: false
                    )
                    notificationToggleRow(
                        icon: "clock",
                        iconColor: Color(.ripeWarn),
                        title: L10n.Settings.expiringSoon,
                        detail: "3 days before",
                        isOn: $store.preferences.sending(\.preferenceToggled).expiringSoon,
                        isLast: false
                    )
                    notificationToggleRow(
                        icon: "shippingbox",
                        iconColor: Color(.ripeCat5),
                        title: L10n.Settings.runningLow,
                        detail: "At reorder point",
                        isOn: $store.preferences.sending(\.preferenceToggled).runningLow,
                        isLast: false
                    )
                    notificationToggleRow(
                        icon: "bell",
                        iconColor: Color(.ripeInk2),
                        title: L10n.Settings.weeklyDigest,
                        detail: "Sunday summary",
                        isOn: $store.preferences.sending(\.preferenceToggled).weeklyDigest,
                        isLast: true
                    )
                }
            }
        }
    }

    private var aboutSectionView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            SectionLabel(title: L10n.Settings.sectionAbout)
            RipeCard(padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "questionmark.circle",
                        iconColor: Color(.ripeInk2),
                        title: L10n.Settings.helpAndFeedback,
                        isLast: false
                    ) {
                        store.send(.helpTapped)
                    }
                    settingsRow(
                        icon: "lock.shield",
                        iconColor: Color(.ripeInk2),
                        title: L10n.Settings.privacyPolicy,
                        isLast: false
                    ) {
                        store.send(.privacyPolicyTapped)
                    }
                    signOutRowView
                }
            }
        }
    }

    private var signOutRowView: some View {
        Button {
            store.send(.signOutTapped)
        } label: {
            HStack(spacing: RipeSpacing.s3) {
                iconTileView(systemName: "rectangle.portrait.and.arrow.right", color: Color(.ripeDanger))
                Text(L10n.Settings.signOutRow)
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeDanger))
                Spacer()
            }
            .padding(.horizontal, RipeSpacing.s4)
            .padding(.vertical, RipeSpacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

extension SettingsView {
    private var displayName: String {
        if let name = store.user?.displayName, !name.isEmpty {
            return name
        }
        if let email = store.user?.email,
           let prefix = email.split(separator: "@").first,
           !prefix.isEmpty {
            return String(prefix)
        }
        return L10n.Settings.fallbackDisplayName
    }

    private var providerDisplayName: String {
        switch store.user?.authProvider {
        case "apple": "Apple"
        case "google": "Google"
        default: ""
        }
    }

    private var planDisplayName: String {
        store.user?.subscriptionTier.capitalized ?? L10n.Settings.planFreeName
    }

    private var userInitials: String {
        let words = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
        return words.isEmpty ? "?" : words.joined()
    }

    private func iconTileView(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .iconFont(.md)
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous)
                    .fill(color.opacity(0.1))
            )
    }

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String? = nil,
        isLast: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: RipeSpacing.s3) {
                    iconTileView(systemName: icon, color: iconColor)
                    Text(title)
                        .customFont(.semibold15)
                        .foregroundStyle(Color(.ripeInk))
                    Spacer()
                    if let value {
                        Text(value)
                            .customFont(.medium12)
                            .foregroundStyle(Color(.ripeInk2))
                    }
                    Image(systemName: "chevron.right")
                        .iconFont(.sm)
                        .foregroundStyle(Color(.ripeInk3))
                }
                .padding(.horizontal, RipeSpacing.s4)
                .padding(.vertical, RipeSpacing.s3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isLast {
                Color(.ripeLine)
                    .frame(height: 1)
                    .padding(.leading, RipeSpacing.s4 + 36 + RipeSpacing.s3)
            }
        }
    }

    private func notificationToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        detail: String,
        isOn: Binding<Bool>,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: RipeSpacing.s3) {
                iconTileView(systemName: icon, color: iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .customFont(.semibold15)
                        .foregroundStyle(Color(.ripeInk))
                    Text(detail)
                        .customFont(.medium12)
                        .foregroundStyle(Color(.ripeInk2))
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color(.ripeAccent))
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
}

// MARK: - Preview

#Preview {
    SettingsView(store: Store(initialState: SettingsFeature.State()) {
        SettingsFeature()
    })
}
