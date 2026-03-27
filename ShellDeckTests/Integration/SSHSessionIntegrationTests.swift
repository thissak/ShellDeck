import XCTest
@testable import ShellDeck

/// 실제 SSH 서버에 접속하는 통합 테스트.
/// 환경변수 SHELLDECK_SSH_TEST=1 일 때만 실행.
/// 대상: alfred (1.232.27.15:2222, user: afred, ed25519 키)
final class SSHSessionIntegrationTests: XCTestCase {

    var session: SSHSession!
    var keychainService: MockKeychainService!

    override func setUp() {
        guard ProcessInfo.processInfo.environment["SHELLDECK_SSH_TEST"] == "1" else { return }

        keychainService = MockKeychainService()

        // ed25519 키 파일을 Keychain Mock에 저장
        let keyPath = NSString("~/.ssh/id_ed25519").expandingTildeInPath
        if let keyData = FileManager.default.contents(atPath: keyPath) {
            let keyId = UUID()
            try? keychainService.storePrivateKey(keyData, for: keyId)

            let host = SSHHost(
                name: "alfred",
                hostname: "1.232.27.15",
                port: 2222,
                username: "afred",
                authMethod: .key(keyId: keyId)
            )
            session = SSHSession(host: host, keychainService: keychainService)
        }
    }

    override func tearDown() {
        session?.disconnect()
    }

    func testRealSSHConnection() async throws {
        guard ProcessInfo.processInfo.environment["SHELLDECK_SSH_TEST"] == "1" else {
            throw XCTSkip("Set SHELLDECK_SSH_TEST=1 to run integration tests")
        }

        // Connect
        try await session.connect()
        XCTAssertEqual(session.state, .connected)

        // Execute command
        let result = try await session.executeCommand("whoami")
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "afred")
    }

    func testRealSSHCommandExecution() async throws {
        guard ProcessInfo.processInfo.environment["SHELLDECK_SSH_TEST"] == "1" else {
            throw XCTSkip("Set SHELLDECK_SSH_TEST=1 to run integration tests")
        }

        try await session.connect()

        let result = try await session.executeCommand("echo hello_shelldeck")
        XCTAssertTrue(result.contains("hello_shelldeck"))
    }

    func testRealSSHDisconnect() async throws {
        guard ProcessInfo.processInfo.environment["SHELLDECK_SSH_TEST"] == "1" else {
            throw XCTSkip("Set SHELLDECK_SSH_TEST=1 to run integration tests")
        }

        try await session.connect()
        XCTAssertEqual(session.state, .connected)

        session.disconnect()
        XCTAssertEqual(session.state, .disconnected)
    }
}
