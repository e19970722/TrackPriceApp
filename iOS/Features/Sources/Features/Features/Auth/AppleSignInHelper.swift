import AuthenticationServices
import Foundation

struct AppleSignInResult {
    let identityToken: String
    /// Formatted full name; non-nil only on the user's first sign-in with Apple.
    let fullName: String?
}

enum AppleSignInHelper {
    static func requestToken() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = delegate
            // Hold delegate alive for the duration of the request
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            controller.performRequests()
        }
    }
}

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<AppleSignInResult, Error>

    init(continuation: CheckedContinuation<AppleSignInResult, Error>) {
        self.continuation = continuation
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            continuation.resume(throwing: AuthError.missingToken)
            return
        }
        continuation.resume(returning: AppleSignInResult(
            identityToken: token,
            fullName: cred.fullName.flatMap(Self.formattedName)
        ))
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation.resume(throwing: error)
    }

    private static func formattedName(_ components: PersonNameComponents) -> String? {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let name = formatter.string(from: components).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}

public enum AuthError: LocalizedError {
    case missingToken

    public var errorDescription: String? {
        "Could not retrieve sign-in token."
    }
}
