import GoogleSignIn
import UIKit

enum GoogleSignInHelper {
    static func requestToken() async throws -> String {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw AuthError.missingToken
        }
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    continuation.resume(throwing: AuthError.missingToken)
                    return
                }
                continuation.resume(returning: idToken)
            }
        }
    }
}
