import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()

    let keychainService: KeychainServiceProtocol
    let hostKeyService: HostKeyServiceProtocol
    let hostStorage: HostStorageProtocol
    let configParser: SSHConfigParserProtocol

    private init() {
        keychainService = KeychainService()

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ShellDeck", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        hostKeyService = HostKeyService(storageDirectory: appSupport)
        hostStorage = HostStorage(directory: appSupport)
        configParser = SSHConfigParser()
    }

    func makeSSHSession(for host: SSHHost) -> SSHSession {
        SSHSession(host: host, keychainService: keychainService)
    }
}
