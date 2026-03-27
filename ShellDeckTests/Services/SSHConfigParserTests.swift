import XCTest
@testable import ShellDeck

final class SSHConfigParserTests: XCTestCase {

    var parser: SSHConfigParser!

    override func setUp() {
        parser = SSHConfigParser()
    }

    func testParseSingleHost() throws {
        let config = """
        Host myserver
            HostName 192.168.1.100
            Port 2222
            User admin
        """
        let hosts = try parser.parse(config)

        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].name, "myserver")
        XCTAssertEqual(hosts[0].hostname, "192.168.1.100")
        XCTAssertEqual(hosts[0].port, 2222)
        XCTAssertEqual(hosts[0].username, "admin")
    }

    func testParseMultipleHosts() throws {
        let config = """
        Host server1
            HostName 10.0.0.1
            User root

        Host server2
            HostName 10.0.0.2
            User deploy
            Port 22022
        """
        let hosts = try parser.parse(config)

        XCTAssertEqual(hosts.count, 2)
        XCTAssertEqual(hosts[0].name, "server1")
        XCTAssertEqual(hosts[1].name, "server2")
        XCTAssertEqual(hosts[1].port, 22022)
    }

    func testParseDefaultPort() throws {
        let config = """
        Host noport
            HostName example.com
            User user
        """
        let hosts = try parser.parse(config)

        XCTAssertEqual(hosts[0].port, 22)
    }

    func testParseCommentsAndBlankLines() throws {
        let config = """
        # This is a comment
        Host myhost
            # Another comment
            HostName example.com

            User testuser
        """
        let hosts = try parser.parse(config)

        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].hostname, "example.com")
        XCTAssertEqual(hosts[0].username, "testuser")
    }

    func testParseLocalForward() throws {
        let config = """
        Host tunnel
            HostName proxy.example.com
            User tunneler
            LocalForward 8080 localhost:80
            LocalForward 3306 db.internal:3306
        """
        let hosts = try parser.parse(config)

        XCTAssertEqual(hosts[0].localForwards.count, 2)
        XCTAssertEqual(hosts[0].localForwards[0].localPort, 8080)
        XCTAssertEqual(hosts[0].localForwards[0].remoteHost, "localhost")
        XCTAssertEqual(hosts[0].localForwards[0].remotePort, 80)
        XCTAssertEqual(hosts[0].localForwards[1].localPort, 3306)
    }

    func testParseRemoteForward() throws {
        let config = """
        Host reverse
            HostName remote.example.com
            User user
            RemoteForward 9090 localhost:8080
        """
        let hosts = try parser.parse(config)

        XCTAssertEqual(hosts[0].remoteForwards.count, 1)
        XCTAssertEqual(hosts[0].remoteForwards[0].localPort, 9090)
        XCTAssertEqual(hosts[0].remoteForwards[0].remoteHost, "localhost")
        XCTAssertEqual(hosts[0].remoteForwards[0].remotePort, 8080)
    }

    func testParseWildcardHostSkipped() throws {
        let config = """
        Host *
            ServerAliveInterval 60

        Host real
            HostName real.com
            User user
        """
        let hosts = try parser.parse(config)

        // Wildcard blocks should be skipped (no hostname)
        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].name, "real")
    }

    func testParseMalformedInputSkipsBlock() throws {
        let config = """
        Host broken

        Host valid
            HostName ok.com
            User user
        """
        let hosts = try parser.parse(config)

        // "broken" has no HostName, should be skipped
        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].name, "valid")
    }

    func testExportAndReparse() throws {
        let original = SSHHost(
            name: "roundtrip",
            hostname: "rt.example.com",
            port: 2222,
            username: "rtuser",
            authMethod: .password,
            localForwards: [SSHHost.PortForward(localPort: 8080, remoteHost: "localhost", remotePort: 80)]
        )

        let exported = parser.export([original])
        let reparsed = try parser.parse(exported)

        XCTAssertEqual(reparsed.count, 1)
        XCTAssertEqual(reparsed[0].name, "roundtrip")
        XCTAssertEqual(reparsed[0].hostname, "rt.example.com")
        XCTAssertEqual(reparsed[0].port, 2222)
        XCTAssertEqual(reparsed[0].username, "rtuser")
        XCTAssertEqual(reparsed[0].localForwards.count, 1)
    }

    func testParseEmptyString() throws {
        let hosts = try parser.parse("")
        XCTAssertTrue(hosts.isEmpty)
    }
}
