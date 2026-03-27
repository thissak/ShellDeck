import Foundation

struct MoshConnectionInfo: Equatable {
    let host: String
    let port: UInt16
    let key: String
}

enum MoshBootstrapError: Error, Equatable {
    case noMoshConnectLine
    case invalidPort(String)
    case invalidKeyLength(Int)
    case malformedOutput
}

enum MoshBootstrap {
    /// Parses mosh-server output to extract connection info.
    /// Expected format: "MOSH CONNECT <port> <key>"
    static func parse(_ serverOutput: String, host: String) throws -> MoshConnectionInfo {
        let lines = serverOutput.components(separatedBy: .newlines)

        guard let connectLine = lines.first(where: { $0.hasPrefix("MOSH CONNECT ") }) else {
            throw MoshBootstrapError.noMoshConnectLine
        }

        let parts = connectLine.split(separator: " ")
        guard parts.count == 4 else {
            throw MoshBootstrapError.malformedOutput
        }

        let portString = String(parts[2])
        guard let port = UInt16(portString) else {
            throw MoshBootstrapError.invalidPort(portString)
        }

        let key = String(parts[3])
        guard key.count == 22 else {
            throw MoshBootstrapError.invalidKeyLength(key.count)
        }

        return MoshConnectionInfo(host: host, port: port, key: key)
    }
}
