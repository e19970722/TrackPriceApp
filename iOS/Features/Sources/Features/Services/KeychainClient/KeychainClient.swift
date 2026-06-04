import ComposableArchitecture
import Foundation
import Security

public struct KeychainClient {
    public var saveToken: @Sendable (String) -> Void
    public var loadToken: @Sendable () -> String?
    public var deleteToken: @Sendable () -> Void
}

private let tokenKey = "jwt_token"

extension KeychainClient: DependencyKey {
    public static var liveValue: KeychainClient {
        KeychainClient(
            saveToken: { token in
                let data = Data(token.utf8)
                let query: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: tokenKey,
                    kSecValueData: data,
                ]
                SecItemDelete(query as CFDictionary)
                SecItemAdd(query as CFDictionary, nil)
            },
            loadToken: {
                let query: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: tokenKey,
                    kSecReturnData: true,
                    kSecMatchLimit: kSecMatchLimitOne,
                ]
                var result: AnyObject?
                guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
                      let data = result as? Data else { return nil }
                return String(data: data, encoding: .utf8)
            },
            deleteToken: {
                let query: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: tokenKey,
                ]
                SecItemDelete(query as CFDictionary)
            }
        )
    }

    public static var testValue: KeychainClient {
        let storage = LockIsolated<String?>(nil)
        return KeychainClient(
            saveToken: { storage.setValue($0) },
            loadToken: { storage.value },
            deleteToken: { storage.setValue(nil) }
        )
    }
}

public extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClient.self] }
        set { self[KeychainClient.self] = newValue }
    }
}
