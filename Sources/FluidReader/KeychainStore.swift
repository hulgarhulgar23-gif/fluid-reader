import Foundation
import Security

enum KeychainStore {
    /// Stores the value, replacing any existing item. Returns `false` when the
    /// Keychain write fails so callers can surface the problem instead of
    /// silently losing the secret.
    @discardableResult
    static func set(_ value: String, service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let deleteStatus = SecItemDelete(query as CFDictionary)

        guard !value.isEmpty, let data = value.data(using: .utf8) else {
            return deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound
        }

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus != errSecSuccess {
            NSLog("KeychainStore: failed to store item for %@/%@ (OSStatus %d)", service, account, addStatus)
            return false
        }
        return true
    }

    static func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
