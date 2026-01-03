import CryptoKit
import Security
import Foundation
import SmithereenAPI

func secureRandomBytes(count: Int) -> Data {
    var data = Data(count: count)

    var result: OSStatus
    repeat {
        result = data.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
            SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
        }
    } while result != errSecSuccess

    return data
}

extension String {
    func sha256() -> Data {
        var hasher = SHA256()
        var s = self
        s.withUTF8 {
            hasher.update(bufferPointer: UnsafeRawBufferPointer($0))
        }
        return Data(hasher.finalize())
    }
}

struct KeychainAccess {
    let service: String

    struct Error: Swift.Error {
        var status: OSStatus
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private func accountName(_ session: SessionInfo) -> String {
        var account = "id\(session.userID)@\(session.host)"
        if let port = session.port {
            account += ":\(port)"
        }
        return account
    }

    func storeSession(_ session: SessionInfo) throws {
        let attributes = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : service,
            kSecAttrAccount : accountName(session),
            kSecValueData : try Self.encoder.encode(session),
        ] as CFDictionary

        let status = SecItemAdd(attributes, nil)
        if status != errSecSuccess {
            throw Error(status: status)
        }
    }

    func retrieveSession() throws -> SessionInfo? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        if status == errSecItemNotFound {
            return nil
        }

        if status != errSecSuccess {
            throw Error(status: status)
        }

        guard let data = result as? Data else {
            return nil
        }

        return try Self.decoder.decode(SessionInfo.self, from: data)
    }

    func clear() throws {
        let query = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService: service,
        ] as CFDictionary

        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw Error(status: status)
        }
    }
}

extension KeychainAccess.Error: LocalizedError {
    var errorDescription: String? {
        SecCopyErrorMessageString(status, nil) as String?
    }
}
