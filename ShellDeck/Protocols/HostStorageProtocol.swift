import Foundation

protocol HostStorageProtocol {
    func saveHosts(_ hosts: [SSHHost]) throws
    func loadHosts() throws -> [SSHHost]
    func saveKeys(_ keys: [SSHKey]) throws
    func loadKeys() throws -> [SSHKey]
}
