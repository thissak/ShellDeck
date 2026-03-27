import XCTest
@testable import ShellDeck

final class KeychainServiceTests: XCTestCase {

    var service: KeychainService!
    let testHostId = UUID()
    let testKeyId = UUID()

    override func setUp() {
        service = KeychainService(servicePrefix: "com.shelldeck.test.\(UUID().uuidString)")
    }

    override func tearDown() {
        try? service.deletePassword(for: testHostId)
        try? service.deletePrivateKey(for: testKeyId)
    }

    func testStoreAndRetrievePassword() throws {
        try service.storePassword("secret123", for: testHostId)
        let retrieved = try service.retrievePassword(for: testHostId)
        XCTAssertEqual(retrieved, "secret123")
    }

    func testStoreAndRetrievePrivateKey() throws {
        let keyData = Data("private-key-content".utf8)
        try service.storePrivateKey(keyData, for: testKeyId)
        let retrieved = try service.retrievePrivateKey(for: testKeyId)
        XCTAssertEqual(retrieved, keyData)
    }

    func testDeletePassword() throws {
        try service.storePassword("todelete", for: testHostId)
        try service.deletePassword(for: testHostId)
        let retrieved = try service.retrievePassword(for: testHostId)
        XCTAssertNil(retrieved)
    }

    func testOverwritePassword() throws {
        try service.storePassword("old", for: testHostId)
        try service.storePassword("new", for: testHostId)
        let retrieved = try service.retrievePassword(for: testHostId)
        XCTAssertEqual(retrieved, "new")
    }

    func testRetrieveNonExistentPassword() throws {
        let retrieved = try service.retrievePassword(for: UUID())
        XCTAssertNil(retrieved)
    }
}
