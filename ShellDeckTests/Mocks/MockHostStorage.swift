import Foundation
@testable import ShellDeck

final class MockHostStorage: HostStorageProtocol {
    var hosts: [SSHHost] = []
    var keys: [SSHKey] = []
    var saveHostsCallCount = 0
    var saveKeysCallCount = 0

    func saveHosts(_ hosts: [SSHHost]) throws {
        saveHostsCallCount += 1
        self.hosts = hosts
    }

    func loadHosts() throws -> [SSHHost] {
        hosts
    }

    func saveKeys(_ keys: [SSHKey]) throws {
        saveKeysCallCount += 1
        self.keys = keys
    }

    func loadKeys() throws -> [SSHKey] {
        keys
    }
}
