import Foundation
import KeychainAccess

final class KeychainService: KeychainServiceProtocol {

    private let keychain: Keychain

    init(servicePrefix: String = "com.shelldeck") {
        self.keychain = Keychain(service: servicePrefix)
    }

    func storePassword(_ password: String, for hostId: UUID) throws {
        try keychain.set(password, key: "password-\(hostId.uuidString)")
    }

    func retrievePassword(for hostId: UUID) throws -> String? {
        try keychain.get("password-\(hostId.uuidString)")
    }

    func deletePassword(for hostId: UUID) throws {
        try keychain.remove("password-\(hostId.uuidString)")
    }

    func storePrivateKey(_ keyData: Data, for keyId: UUID) throws {
        try keychain.set(keyData, key: "key-\(keyId.uuidString)")
    }

    func retrievePrivateKey(for keyId: UUID) throws -> Data? {
        try keychain.getData("key-\(keyId.uuidString)")
    }

    func deletePrivateKey(for keyId: UUID) throws {
        try keychain.remove("key-\(keyId.uuidString)")
    }
}
