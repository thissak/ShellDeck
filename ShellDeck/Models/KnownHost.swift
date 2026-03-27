import Foundation

struct KnownHost: Codable, Identifiable, Hashable {
    let id: UUID
    var hostname: String
    var port: UInt16
    var keyType: String
    var fingerprint: String
    var firstSeen: Date
    var lastSeen: Date

    init(
        id: UUID = UUID(),
        hostname: String,
        port: UInt16,
        keyType: String,
        fingerprint: String,
        firstSeen: Date = Date(),
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.hostname = hostname
        self.port = port
        self.keyType = keyType
        self.fingerprint = fingerprint
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
    }
}
