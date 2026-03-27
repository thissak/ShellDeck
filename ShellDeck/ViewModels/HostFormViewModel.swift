import Foundation

final class HostFormViewModel {

    var name: String = ""
    var hostname: String = ""
    var username: String = ""
    var port: String = "22"
    var useMosh: Bool = false

    var isValid: Bool {
        guard !hostname.isEmpty, !username.isEmpty else { return false }
        guard let p = UInt16(port), p > 0 else { return false }
        return true
    }

    func buildHost() -> SSHHost {
        SSHHost(
            name: name,
            hostname: hostname,
            port: UInt16(port) ?? 22,
            username: username,
            useMosh: useMosh
        )
    }
}
