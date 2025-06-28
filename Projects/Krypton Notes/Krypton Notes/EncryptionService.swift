import Foundation
import CryptoKit
import Security

enum EncryptionError: Error {
    case keyGenerationFailed
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
    case dataToStringConversionFailed
    case stringToDataConversionFailed
}

class EncryptionService {

    private let keychainGroup = "group.dunamismax.Krypton-Notes"
    private let keyAlias = "com.dunamismax.KryptonNotes.encryptionKey"

    init() {
        // On initialization, check if the key exists. If not, create it.
        // This ensures the key is ready when needed.
        do {
            if try retrieveKey() == nil {
                _ = try generateAndStoreKey()
            }
        } catch {
            // This is a critical failure. In a real app, you might want to
            // alert the user or enter a state where functionality is disabled.
            fatalError("Failed to initialize encryption key: \(error)")
        }
    }

    // MARK: - Key Management

    private func generateAndStoreKey() throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data(Array($0)) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrAccessGroup as String: keychainGroup
        ]

        // Delete any old key first
        SecItemDelete(query as CFDictionary)

        // Add the new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }
        return key
    }

    private func retrieveKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: keychainGroup
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            guard let keyData = dataTypeRef as? Data else { return nil }
            return SymmetricKey(data: keyData)
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw EncryptionError.keyNotFound
        }
    }

    // MARK: - Data Encryption / Decryption

    func encrypt(string: String) throws -> Data {
        guard let key = try retrieveKey() else {
            throw EncryptionError.keyNotFound
        }
        guard let dataToEncrypt = string.data(using: .utf8) else {
            throw EncryptionError.stringToDataConversionFailed
        }

        do {
            let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
            return sealedBox.combined!
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(data: Data) throws -> String {
        guard let key = try retrieveKey() else {
            throw EncryptionError.keyNotFound
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw EncryptionError.dataToStringConversionFailed
            }
            return decryptedString
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
}
