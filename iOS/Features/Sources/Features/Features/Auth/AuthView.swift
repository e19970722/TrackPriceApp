import AuthenticationServices
import ComposableArchitecture
import SwiftUI

public struct AuthView: View {
    @Perception.Bindable var store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                authContentView
                if store.isLoading {
                    loadingOverlayView
                }
            }
        }
    }
}

// MARK: - Subviews

extension AuthView {
    private var authContentView: some View {
        VStack(spacing: 0) {
            Spacer()
            logoSectionView
            Spacer()
            signInButtonsSection
            errorMessageLabel
            Spacer()
                .frame(height: 48)
        }
    }

    private var logoSectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text(L10n.Auth.appName)
                .font(.largeTitle.bold())

            Text(L10n.Auth.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 56)
    }

    private var signInButtonsSection: some View {
        VStack(spacing: 16) {
            appleSignInButton
            googleSignInButton
        }
        .padding(.horizontal, 32)
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { _ in
            // Handled by the reducer via AppleSignInHelper
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .cornerRadius(10)
        .onTapGesture {
            store.send(.appleSignInTapped)
        }
        // Disable the native completion handler — TCA handles the full flow
        .disabled(store.isLoading)
    }

    private var googleSignInButton: some View {
        GoogleSignInButton {
            store.send(.googleSignInTapped)
        }
        .disabled(store.isLoading)
    }

    @ViewBuilder
    private var errorMessageLabel: some View {
        if let errorMessage = store.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 32)
        }
    }

    private var loadingOverlayView: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.6)
                .ignoresSafeArea()
            ProgressView()
                .scaleEffect(1.4)
        }
    }
}

// MARK: - GoogleSignInButton

private struct GoogleSignInButton: View {
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            googleButtonLabel
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subviews

extension GoogleSignInButton {
    private var googleButtonLabel: some View {
        HStack(spacing: 10) {
            GoogleLogoShape()
                .frame(width: 20, height: 20)

            Text(L10n.Auth.signInWithGoogle)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color(.label))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

// MARK: - GoogleLogoShape

private struct GoogleLogoShape: View {
    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            googleLogoCanvas(size: size)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Subviews

extension GoogleLogoShape {
    private func googleLogoCanvas(size: CGFloat) -> some View {
        ZStack {
            coloredArcStack(size: size)
            whiteGCutoutBar(size: size)
            blueExtensionBar(size: size)
        }
    }

    private func coloredArcStack(size: CGFloat) -> some View {
        ZStack {
            // Simplified Google "G" using colored arcs
            Circle()
                .trim(from: 0.125, to: 0.375)
                .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: size * 0.28)
            Circle()
                .trim(from: 0.375, to: 0.625)
                .stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: size * 0.28)
            Circle()
                .trim(from: 0.625, to: 0.875)
                .stroke(Color(red: 0.99, green: 0.73, blue: 0.02), lineWidth: size * 0.28)
            Circle()
                .trim(from: 0.875, to: 1.125)
                .stroke(Color(red: 0.20, green: 0.66, blue: 0.33), lineWidth: size * 0.28)
        }
    }

    private func whiteGCutoutBar(size: CGFloat) -> some View {
        // White horizontal bar for the "G" cutout
        Rectangle()
            .fill(Color(.systemBackground))
            .frame(width: size * 0.55, height: size * 0.28)
            .offset(x: size * 0.27)
    }

    private func blueExtensionBar(size: CGFloat) -> some View {
        // Blue bar extending right
        Rectangle()
            .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
            .frame(width: size * 0.28, height: size * 0.28)
            .offset(x: size * 0.27)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        AuthView(
            store: Store(initialState: AuthFeature.State()) {
                AuthFeature()
            }
        )
    }

    #Preview("Loading") {
        AuthView(
            store: Store(initialState: AuthFeature.State(isLoading: true)) {
                AuthFeature()
            }
        )
    }

    #Preview("Error") {
        AuthView(
            store: Store(
                initialState: AuthFeature.State(
                    isLoading: false,
                    errorMessage: "Sign in failed. Please try again."
                )
            ) {
                AuthFeature()
            }
        )
    }
#endif
