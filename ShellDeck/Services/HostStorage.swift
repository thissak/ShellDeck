import Foundation

final class HostStorage: HostStorageProtocol {

    private let directory: URL
    private var hostsURL: URL { directory.appendingPathComponent("hosts.json") }
    private var keysURL: URL { directory.appendingPathComponent("keys.json") }

    init(directory: URL) {
        self.directory = directory
    }

    func saveHosts(_ hosts: [SSHHost]) throws {
        let data = try JSONEncoder().encode(hosts)
        try data.write(to: hostsURL)
    }

    func loadHosts() throws -> [SSHHost] {
        guard FileManager.default.fileExists(atPath: hostsURL.path) else { return [] }
        let data = try Data(contentsOf: hostsURL)
        return try JSONDecoder().decode([SSHHost].self, from: data)
    }

    func saveKeys(_ keys: [SSHKey]) throws {
        let data = try JSONEncoder().encode(keys)
        try data.write(to: keysURL)
    }

    func loadKeys() throws -> [SSHKey] {
        guard FileManager.default.fileExists(atPath: keysURL.path) else { return [] }
        let data = try Data(contentsOf: keysURL)
        return try JSONDecoder().decode([SSHKey].self, from: data)
    }
}
