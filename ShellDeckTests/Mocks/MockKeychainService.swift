import Foundation
@testable import ShellDeck

final class MockKeychainService: KeychainServiceProtocol {
    var passwords: [UUID: String] = [:]
    var privateKeys: [UUID: Data] = [:]

    func storePassword(_ password: String, for hostId: UUID) throws {
        passwords[hostId] = password
    }

    func retrievePassword(for hostId: UUID) throws -> String? {
        passwords[hostId]
    }

    func deletePassword(for hostId: UUID) throws {
        passwords.removeValue(forKey: hostId)
    }

    func storePrivateKey(_ keyData: Data, for keyId: UUID) throws {
        privateKeys[keyId] = keyData
    }

    func retrievePrivateKey(for keyId: UUID) throws -> Data? {
        privateKeys[keyId]
    }

    func deletePrivateKey(for keyId: UUID) throws {
        privateKeys.removeValue(forKey: keyId)
    }
}
