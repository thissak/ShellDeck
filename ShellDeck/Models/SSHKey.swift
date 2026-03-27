import Foundation

struct SSHKey: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var keyType: KeyType
    var publicKeyData: Data
    var fingerprint: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        keyType: KeyType,
        publicKeyData: Data,
        fingerprint: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.keyType = keyType
        self.publicKeyData = publicKeyData
        self.fingerprint = fingerprint
        self.createdAt = createdAt
    }

    enum KeyType: String, Codable {
        case ed25519
        case rsa4096
        case ecdsa256
    }
}
