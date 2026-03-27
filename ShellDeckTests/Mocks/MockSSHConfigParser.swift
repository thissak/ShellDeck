import Foundation
@testable import ShellDeck

final class MockSSHConfigParser: SSHConfigParserProtocol {
    var parseResult: [SSHHost] = []
    var parseError: Error?
    var parseCallCount = 0
    var lastParsedString: String?
    var exportResult = ""

    func parse(_ configString: String) throws -> [SSHHost] {
        parseCallCount += 1
        lastParsedString = configString
        if let error = parseError { throw error }
        return parseResult
    }

    func export(_ hosts: [SSHHost]) -> String {
        exportResult
    }
}
