import ComposableArchitecture
import SwiftUI

public struct SettingsView: View {
    @Perception.Bindable var store: StoreOf<SettingsFeature>

    // Fallback local toggles for notification rows not yet in TCA state
    @State private var priceDropsOn: Bool = true
    @State private var expiringSoonOn: Bool = true
    @State private var runningLowOn: Bool = true
    @State private var weeklyDigestOn: Bool = false

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            scrollContentView
                .background(Color(.ripeBg).ignoresSafeArea())
                .confirmationDialog(
                    "Sign out of TrackPrice?",
                    isPresented: Binding(
                        get: { store.isSignOutConfirmationPresented },
                        set: { _ in store.send(.signOutCancelled) }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Sign Out", role: .destructive) {
                        store.send(.signOutConfirmed)
                    }
                    Button("Cancel", role: .cancel) {
                        store.send(.signOutCancelled)
                    }
                }
        }
    }
}

// MARK: - Subviews

extension SettingsView {

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
                    .font(RipeFont.display(26))
                    .foregroundStyle(Color(.ripeInk))
                Text(displayEmail)
                    .font(RipeFont.caption(13.5))
                    .foregroundStyle(Color(.ripeInk3))
            }
            Spacer()
        }
    }

    private var accountSectionView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            SectionLabel(title: "Account")
            RipeCard(padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "creditcard",
                        iconColor: Color(.ripeCat5),
                        title: "Connected accounts",
                        value: "Apple · Google",
                        isLast: false
                    )
                    settingsRow(
                        icon: "dollarsign.circle",
                        iconColor: Color(.ripeGood),
                        title: "Default currency",
                        value: "USD $",
                        isLast: false
                    )
                    settingsRow(
                        icon: "storefront",
                        iconColor: Color(.ripeWarn),
                        title: "Preferred stores",
                        value: "3",
                        isLast: false
                    )
                    settingsRow(
                        icon: "sparkles",
                        iconColor: Color(.ripeAccent),
                        title: "Plan",
                        value: "Free",
                        isLast: true
                    )
                }
            }
        }
    }

    private var notificationsSectionView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            SectionLabel(title: "Notifications")
            RipeCard(padding: 0) {
                VStack(spacing: 0) {
                    notificationToggleRow(
                        icon: "tag",
                        iconColor: Color(.ripeCat1),
                        title: "Price drops",
                        detail: "When a track hits target",
                        isOn: $priceDropsOn,
                        isLast: false
                    )
                    notificationToggleRow(
                        icon: "clock",
                        iconColor: Color(.ripeWarn),
                        title: "Expiring soon",
                        detail: "3 days before",
                        isOn: $expiringSoonOn,
                        isLast: false
                    )
                    notificationToggleRow(
                        icon: "shippingbox",
                        iconColor: Color(.ripeCat5),
                        title: "Running low",
                        detail: "At reorder point",
                        isOn: $runningLowOn,
                        isLast: false
                    )
                    notificationToggleRow(
                        icon: "bell",
                        iconColor: Color(.ripeInk2),
                        title: "Weekly digest",
                        detail: "Sunday summary",
                        isOn: $weeklyDigestOn,
                        isLast: true
                    )
                }
            }
        }
    }

    private var aboutSectionView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s3) {
            SectionLabel(title: "About")
            RipeCard(padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "questionmark.circle",
                        iconColor: Color(.ripeInk2),
                        title: "Help & feedback",
                        value: nil,
                        isLast: false
                    )
                    settingsRow(
                        icon: "lock.shield",
                        iconColor: Color(.ripeInk2),
                        title: "Privacy policy",
                        value: nil,
                        isLast: false
                    )
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
                Text("Sign out")
                    .font(RipeFont.body(15.5))
                    .foregroundStyle(Color(.ripeDanger))
                Spacer()
            }
            .padding(.horizontal, RipeSpacing.s4)
            .padding(.vertical, RipeSpacing.s3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

extension SettingsView {

    private var displayName: String {
        // SettingsFeature.State does not yet expose a display name field;
        // fall back to "Sam Rivers" as placeholder per spec.
        "Sam Rivers"
    }

    private var displayEmail: String {
        store.userEmail.isEmpty ? "sam@rivers.me" : store.userEmail
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
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous)
                    .fill(color.opacity(0.1))
            )
    }

    @ViewBuilder
    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String?,
        isLast: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: RipeSpacing.s3) {
                iconTileView(systemName: icon, color: iconColor)
                Text(title)
                    .font(RipeFont.body(15.5))
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
                if let value {
                    Text(value)
                        .font(RipeFont.caption(12.5))
                        .foregroundStyle(Color(.ripeInk2))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.ripeInk3))
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

    @ViewBuilder
    private func notificationToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        detail: String,
        isOn: Binding<Bool>,
        isLast: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: RipeSpacing.s3) {
                iconTileView(systemName: icon, color: iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(RipeFont.body(15.5))
                        .foregroundStyle(Color(.ripeInk))
                    Text(detail)
                        .font(RipeFont.caption(12.5))
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
