import Foundation

final class SSHConfigParser: SSHConfigParserProtocol {

    func parse(_ configString: String) throws -> [SSHHost] {
        var hosts: [SSHHost] = []
        var currentName: String?
        var currentHostName: String?
        var currentPort: UInt16 = 22
        var currentUser: String?
        var currentLocalForwards: [SSHHost.PortForward] = []
        var currentRemoteForwards: [SSHHost.PortForward] = []

        func flushBlock() {
            guard let name = currentName,
                  let hostname = currentHostName,
                  let user = currentUser,
                  name != "*" else {
                resetBlock()
                return
            }
            hosts.append(SSHHost(
                name: name,
                hostname: hostname,
                port: currentPort,
                username: user,
                localForwards: currentLocalForwards,
                remoteForwards: currentRemoteForwards
            ))
            resetBlock()
        }

        func resetBlock() {
            currentName = nil
            currentHostName = nil
            currentPort = 22
            currentUser = nil
            currentLocalForwards = []
            currentRemoteForwards = []
        }

        let lines = configString.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let key = String(parts[0])
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "Host":
                flushBlock()
                currentName = value
            case "HostName":
                currentHostName = value
            case "Port":
                currentPort = UInt16(value) ?? 22
            case "User":
                currentUser = value
            case "LocalForward":
                if let forward = parseForward(value) {
                    currentLocalForwards.append(forward)
                }
            case "RemoteForward":
                if let forward = parseForward(value) {
                    currentRemoteForwards.append(forward)
                }
            default:
                break
            }
        }
        flushBlock()

        return hosts
    }

    func export(_ hosts: [SSHHost]) -> String {
        hosts.map { host in
            var lines = ["Host \(host.name)"]
            lines.append("    HostName \(host.hostname)")
            if host.port != 22 {
                lines.append("    Port \(host.port)")
            }
            lines.append("    User \(host.username)")
            for fwd in host.localForwards {
                lines.append("    LocalForward \(fwd.localPort) \(fwd.remoteHost):\(fwd.remotePort)")
            }
            for fwd in host.remoteForwards {
                lines.append("    RemoteForward \(fwd.localPort) \(fwd.remoteHost):\(fwd.remotePort)")
            }
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    private func parseForward(_ value: String) -> SSHHost.PortForward? {
        // Format: "localPort remoteHost:remotePort"
        let parts = value.split(separator: " ", maxSplits: 1)
        guard parts.count == 2,
              let localPort = UInt16(parts[0]) else { return nil }

        let remote = parts[1].split(separator: ":")
        guard remote.count == 2,
              let remotePort = UInt16(remote[1]) else { return nil }

        return SSHHost.PortForward(
            localPort: localPort,
            remoteHost: String(remote[0]),
            remotePort: remotePort
        )
    }
}
