import Foundation

protocol SSHConfigParserProtocol {
    func parse(_ configString: String) throws -> [SSHHost]
    func export(_ hosts: [SSHHost]) -> String
}
