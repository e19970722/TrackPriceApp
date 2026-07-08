import SwiftUI

/// Display-only comparison of the Free and Premium tiers.
/// No in-app purchase — the badge marks the user's current tier.
struct PlanView: View {
    let tier: String // "free" or "premium"

    // MARK: - Body

    var body: some View {
        contentScrollView
            .background(Color(.ripeBg).ignoresSafeArea())
            .navigationTitle(L10n.Settings.plan)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

extension PlanView {
    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s4) {
                freePlanCardView
                premiumPlanCardView
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s6)
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    private var freePlanCardView: some View {
        planCard(
            name: L10n.Settings.planFreeName,
            features: [
                L10n.Settings.planFreeFeatureTrackers,
                L10n.Settings.planFreeFeatureChecks,
            ],
            isCurrent: tier == "free"
        )
    }

    private var premiumPlanCardView: some View {
        planCard(
            name: L10n.Settings.planPremiumName,
            features: [
                L10n.Settings.planPremiumFeatureTrackers,
                L10n.Settings.planPremiumFeatureChecks,
            ],
            isCurrent: tier == "premium"
        )
    }

    private var currentPlanBadgeView: some View {
        Text(L10n.Settings.planCurrentPlan)
            .customFont(.semibold12)
            .foregroundStyle(Color(.ripeAccentInk))
            .padding(.horizontal, RipeSpacing.s3)
            .padding(.vertical, RipeSpacing.s1)
            .background(Capsule().fill(Color(.ripeAccent)))
    }

    private func planCard(name: String, features: [String], isCurrent: Bool) -> some View {
        RipeCard {
            VStack(alignment: .leading, spacing: RipeSpacing.s3) {
                HStack {
                    Text(name)
                        .customFont(.bold19)
                        .foregroundStyle(Color(.ripeInk))
                    Spacer()
                    if isCurrent {
                        currentPlanBadgeView
                    }
                }
                VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                    ForEach(features, id: \.self) { feature in
                        featureRow(feature)
                    }
                }
            }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: RipeSpacing.s2) {
            Image(systemName: "checkmark.circle.fill")
                .iconFont(.sm)
                .foregroundStyle(Color(.ripeGood))
            Text(text)
                .customFont(.medium13)
                .foregroundStyle(Color(.ripeInk2))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlanView(tier: "free")
    }
}
