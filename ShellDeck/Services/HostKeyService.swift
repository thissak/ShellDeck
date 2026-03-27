import Foundation

final class HostKeyService: HostKeyServiceProtocol {

    private let storageURL: URL
    private var hosts: [String: KnownHost] = [:]

    init(storageDirectory: URL) {
        self.storageURL = storageDirectory.appendingPathComponent("known_hosts.json")
        load()
    }

    var allKnownHosts: [KnownHost] {
        Array(hosts.values)
    }

    func verify(hostname: String, port: UInt16, keyType: String, fingerprint: String) -> HostKeyVerification {
        let key = "\(hostname):\(port)"
        guard let stored = hosts[key] else { return .unknown }
        if stored.fingerprint == fingerprint { return .trusted }
        return .mismatch(stored: stored.fingerprint)
    }

    func trust(hostname: String, port: UInt16, keyType: String, fingerprint: String) throws {
        let key = "\(hostname):\(port)"
        hosts[key] = KnownHost(
            hostname: hostname,
            port: port,
            keyType: keyType,
            fingerprint: fingerprint
        )
        try save()
    }

    func remove(hostname: String, port: UInt16) throws {
        let key = "\(hostname):\(port)"
        hosts.removeValue(forKey: key)
        try save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([String: KnownHost].self, from: data) else { return }
        hosts = decoded
    }

    private func save() throws {
        let data = try JSONEncoder().encode(hosts)
        try data.write(to: storageURL)
    }
}
