import XCTest
@testable import ShellDeck

final class ModelCodingTests: XCTestCase {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Host

    func testHostRoundTrip_passwordAuth() throws {
        let host = SSHHost(name: "prod", hostname: "10.0.0.1", port: 22, username: "root", authMethod: .password)
        let data = try encoder.encode(host)
        let decoded = try decoder.decode(SSHHost.self, from: data)

        XCTAssertEqual(decoded.name, "prod")
        XCTAssertEqual(decoded.hostname, "10.0.0.1")
        XCTAssertEqual(decoded.port, 22)
        XCTAssertEqual(decoded.username, "root")
        XCTAssertEqual(decoded.authMethod, .password)
        XCTAssertEqual(decoded.id, host.id)
    }

    func testHostRoundTrip_keyAuth() throws {
        let keyId = UUID()
        let host = SSHHost(name: "staging", hostname: "staging.example.com", username: "deploy", authMethod: .key(keyId: keyId))
        let data = try encoder.encode(host)
        let decoded = try decoder.decode(SSHHost.self, from: data)

        XCTAssertEqual(decoded.authMethod, .key(keyId: keyId))
    }

    func testHostRoundTrip_agentAuth() throws {
        let host = SSHHost(name: "dev", hostname: "dev.local", username: "user", authMethod: .agent)
        let data = try encoder.encode(host)
        let decoded = try decoder.decode(SSHHost.self, from: data)

        XCTAssertEqual(decoded.authMethod, .agent)
    }

    func testHostRoundTrip_withMoshAndForwards() throws {
        let host = SSHHost(
            name: "full",
            hostname: "example.com",
            port: 2222,
            username: "admin",
            authMethod: .password,
            useMosh: true,
            jumpHost: UUID(),
            localForwards: [SSHHost.PortForward(localPort: 8080, remoteHost: "localhost", remotePort: 80)],
            remoteForwards: [SSHHost.PortForward(localPort: 3306, remoteHost: "db.internal", remotePort: 3306)]
        )
        let data = try encoder.encode(host)
        let decoded = try decoder.decode(SSHHost.self, from: data)

        XCTAssertTrue(decoded.useMosh)
        XCTAssertNotNil(decoded.jumpHost)
        XCTAssertEqual(decoded.localForwards.count, 1)
        XCTAssertEqual(decoded.localForwards[0].localPort, 8080)
        XCTAssertEqual(decoded.remoteForwards.count, 1)
    }

    func testHostRoundTrip_nilOptionals() throws {
        let host = SSHHost(name: "minimal", hostname: "h", username: "u")
        let data = try encoder.encode(host)
        let decoded = try decoder.decode(SSHHost.self, from: data)

        XCTAssertNil(decoded.jumpHost)
        XCTAssertNil(decoded.lastConnectedAt)
        XCTAssertTrue(decoded.localForwards.isEmpty)
    }

    func testHostRoundTrip_edgePorts() throws {
        let host1 = SSHHost(name: "low", hostname: "h", port: 0, username: "u")
        let host2 = SSHHost(name: "high", hostname: "h", port: 65535, username: "u")

        let d1 = try encoder.encode(host1)
        let d2 = try encoder.encode(host2)

        XCTAssertEqual(try decoder.decode(SSHHost.self, from: d1).port, 0)
        XCTAssertEqual(try decoder.decode(SSHHost.self, from: d2).port, 65535)
    }

    func testHostRoundTrip_emptyStrings() throws {
        let host = SSHHost(name: "", hostname: "", username: "")
        let data = try encoder.encode(host)
        let decoded = try decoder.decode(SSHHost.self, from: data)

        XCTAssertEqual(decoded.name, "")
        XCTAssertEqual(decoded.hostname, "")
        XCTAssertEqual(decoded.username, "")
    }

    // MARK: - SSHKey

    func testSSHKeyRoundTrip() throws {
        let key = SSHKey(
            name: "my-key",
            keyType: .ed25519,
            publicKeyData: Data([0x01, 0x02, 0x03]),
            fingerprint: "SHA256:abc123"
        )
        let data = try encoder.encode(key)
        let decoded = try decoder.decode(SSHKey.self, from: data)

        XCTAssertEqual(decoded.name, "my-key")
        XCTAssertEqual(decoded.keyType, .ed25519)
        XCTAssertEqual(decoded.publicKeyData, Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(decoded.fingerprint, "SHA256:abc123")
    }

    func testSSHKeyRoundTrip_allKeyTypes() throws {
        for keyType in [SSHKey.KeyType.ed25519, .rsa4096, .ecdsa256] {
            let key = SSHKey(name: "test", keyType: keyType, publicKeyData: Data(), fingerprint: "fp")
            let data = try encoder.encode(key)
            let decoded = try decoder.decode(SSHKey.self, from: data)
            XCTAssertEqual(decoded.keyType, keyType)
        }
    }

    // MARK: - KnownHost

    func testKnownHostRoundTrip() throws {
        let kh = KnownHost(
            hostname: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            fingerprint: "SHA256:xyz789"
        )
        let data = try encoder.encode(kh)
        let decoded = try decoder.decode(KnownHost.self, from: data)

        XCTAssertEqual(decoded.hostname, "example.com")
        XCTAssertEqual(decoded.port, 22)
        XCTAssertEqual(decoded.keyType, "ssh-ed25519")
        XCTAssertEqual(decoded.fingerprint, "SHA256:xyz789")
    }
}
