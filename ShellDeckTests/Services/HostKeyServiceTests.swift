import XCTest
@testable import ShellDeck

final class HostKeyServiceTests: XCTestCase {

    var service: HostKeyService!
    var testDirectory: URL!

    override func setUp() {
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        service = HostKeyService(storageDirectory: testDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
    }

    func testVerifyUnknownHost() {
        let result = service.verify(hostname: "new.host", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:abc")
        XCTAssertEqual(result, .unknown)
    }

    func testTrustThenVerify() throws {
        try service.trust(hostname: "known.host", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:abc")
        let result = service.verify(hostname: "known.host", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:abc")
        XCTAssertEqual(result, .trusted)
    }

    func testVerifyMismatch() throws {
        try service.trust(hostname: "host.com", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:original")
        let result = service.verify(hostname: "host.com", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:different")
        XCTAssertEqual(result, .mismatch(stored: "SHA256:original"))
    }

    func testRemoveThenVerify() throws {
        try service.trust(hostname: "temp.host", port: 22, keyType: "ssh-rsa", fingerprint: "SHA256:temp")
        try service.remove(hostname: "temp.host", port: 22)
        let result = service.verify(hostname: "temp.host", port: 22, keyType: "ssh-rsa", fingerprint: "SHA256:temp")
        XCTAssertEqual(result, .unknown)
    }

    func testSameHostDifferentPort() throws {
        try service.trust(hostname: "multi.host", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:port22")
        try service.trust(hostname: "multi.host", port: 2222, keyType: "ssh-ed25519", fingerprint: "SHA256:port2222")

        XCTAssertEqual(
            service.verify(hostname: "multi.host", port: 22, keyType: "ssh-ed25519", fingerprint: "SHA256:port22"),
            .trusted
        )
        XCTAssertEqual(
            service.verify(hostname: "multi.host", port: 2222, keyType: "ssh-ed25519", fingerprint: "SHA256:port2222"),
            .trusted
        )
    }

    func testAllKnownHosts() throws {
        try service.trust(hostname: "a.com", port: 22, keyType: "ssh-ed25519", fingerprint: "fp1")
        try service.trust(hostname: "b.com", port: 22, keyType: "ssh-rsa", fingerprint: "fp2")

        XCTAssertEqual(service.allKnownHosts.count, 2)
    }
}
