import Foundation

final class HostListViewModel {

    private let storage: HostStorageProtocol
    private let configParser: SSHConfigParserProtocol
    private(set) var hosts: [SSHHost] = []

    init(storage: HostStorageProtocol, configParser: SSHConfigParserProtocol) {
        self.storage = storage
        self.configParser = configParser
    }

    func loadHosts() throws {
        hosts = try storage.loadHosts()
    }

    func addHost(_ host: SSHHost) throws {
        hosts.append(host)
        try storage.saveHosts(hosts)
    }

    func deleteHost(_ host: SSHHost) throws {
        hosts.removeAll { $0.id == host.id }
        try storage.saveHosts(hosts)
    }

    func importSSHConfig(_ configString: String) throws {
        let imported = try configParser.parse(configString)
        hosts.append(contentsOf: imported)
        try storage.saveHosts(hosts)
    }
}
