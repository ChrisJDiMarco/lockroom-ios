import Foundation
import Security

enum KeychainStore {
    private static let service = "com.jarvis.lockroom.openai"
    private static let account = "api-key"

    static func saveAPIKey(_ value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        guard data.isEmpty == false else { return }

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw ImageDevelopmentError.apiFailure("Could not save the API key.")
        }
    }

    static func loadAPIKey() -> String {
        let storedKey = loadStoredAPIKey()
        if storedKey.isEmpty == false {
            return storedKey
        }

        #if DEBUG
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #else
        return ""
        #endif
    }

    private static func loadStoredAPIKey() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard
            status == errSecSuccess,
            let data = result as? Data,
            let key = String(data: data, encoding: .utf8)
        else {
            return ""
        }

        return key
    }
}
