import Foundation

struct SSHHost: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var hostname: String
    var port: UInt16
    var username: String
    var authMethod: AuthMethod
    var useMosh: Bool
    var jumpHost: UUID?
    var localForwards: [PortForward]
    var remoteForwards: [PortForward]
    var createdAt: Date
    var lastConnectedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        hostname: String,
        port: UInt16 = 22,
        username: String,
        authMethod: AuthMethod = .password,
        useMosh: Bool = false,
        jumpHost: UUID? = nil,
        localForwards: [PortForward] = [],
        remoteForwards: [PortForward] = [],
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.useMosh = useMosh
        self.jumpHost = jumpHost
        self.localForwards = localForwards
        self.remoteForwards = remoteForwards
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
    }

    enum AuthMethod: Codable, Hashable {
        case password
        case key(keyId: UUID)
        case agent
    }

    struct PortForward: Codable, Hashable {
        var localPort: UInt16
        var remoteHost: String
        var remotePort: UInt16
    }
}
