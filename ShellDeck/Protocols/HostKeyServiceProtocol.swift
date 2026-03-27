import Foundation

enum HostKeyVerification: Equatable {
    case trusted
    case mismatch(stored: String)
    case unknown
}

protocol HostKeyServiceProtocol {
    func verify(hostname: String, port: UInt16, keyType: String, fingerprint: String) -> HostKeyVerification
    func trust(hostname: String, port: UInt16, keyType: String, fingerprint: String) throws
    func remove(hostname: String, port: UInt16) throws
    var allKnownHosts: [KnownHost] { get }
}
