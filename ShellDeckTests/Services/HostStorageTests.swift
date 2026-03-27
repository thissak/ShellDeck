import XCTest
@testable import ShellDeck

final class HostStorageTests: XCTestCase {

    var storage: HostStorage!
    var testDirectory: URL!

    override func setUp() {
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        storage = HostStorage(directory: testDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
    }

    func testSaveAndLoadHosts() throws {
        let hosts = [
            SSHHost(name: "server1", hostname: "10.0.0.1", username: "root"),
            SSHHost(name: "server2", hostname: "10.0.0.2", port: 2222, username: "deploy"),
        ]
        try storage.saveHosts(hosts)
        let loaded = try storage.loadHosts()

        XCTAssertEqual(loaded.count, 2)
        guard loaded.count == 2 else { return }
        XCTAssertEqual(loaded[0].name, "server1")
        XCTAssertEqual(loaded[1].port, 2222)
    }

    func testSaveAndLoadKeys() throws {
        let keys = [
            SSHKey(name: "key1", keyType: .ed25519, publicKeyData: Data([0x01]), fingerprint: "fp1"),
        ]
        try storage.saveKeys(keys)
        let loaded = try storage.loadKeys()

        XCTAssertEqual(loaded.count, 1)
        guard loaded.count == 1 else { return }
        XCTAssertEqual(loaded[0].name, "key1")
    }

    func testLoadFromEmptyStorage() throws {
        let hosts = try storage.loadHosts()
        let keys = try storage.loadKeys()

        XCTAssertTrue(hosts.isEmpty)
        XCTAssertTrue(keys.isEmpty)
    }
}
