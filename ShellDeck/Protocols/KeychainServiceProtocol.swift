import Foundation

protocol KeychainServiceProtocol {
    func storePassword(_ password: String, for hostId: UUID) throws
    func retrievePassword(for hostId: UUID) throws -> String?
    func deletePassword(for hostId: UUID) throws

    func storePrivateKey(_ keyData: Data, for keyId: UUID) throws
    func retrievePrivateKey(for keyId: UUID) throws -> Data?
    func deletePrivateKey(for keyId: UUID) throws
}
