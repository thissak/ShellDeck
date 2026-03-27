import Foundation
@testable import ShellDeck

final class MockHostKeyService: HostKeyServiceProtocol {
    var knownHosts: [String: KnownHost] = [:]

    var allKnownHosts: [KnownHost] {
        Array(knownHosts.values)
    }

    func verify(hostname: String, port: UInt16, keyType: String, fingerprint: String) -> HostKeyVerification {
        let key = "\(hostname):\(port)"
        guard let stored = knownHosts[key] else { return .unknown }
        if stored.fingerprint == fingerprint {
            return .trusted
        }
        return .mismatch(stored: stored.fingerprint)
    }

    func trust(hostname: String, port: UInt16, keyType: String, fingerprint: String) throws {
        let key = "\(hostname):\(port)"
        knownHosts[key] = KnownHost(
            hostname: hostname,
            port: port,
            keyType: keyType,
            fingerprint: fingerprint
        )
    }

    func remove(hostname: String, port: UInt16) throws {
        let key = "\(hostname):\(port)"
        knownHosts.removeValue(forKey: key)
    }
}
