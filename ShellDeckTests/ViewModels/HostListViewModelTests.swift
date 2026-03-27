import XCTest
@testable import ShellDeck

final class HostListViewModelTests: XCTestCase {

    var viewModel: HostListViewModel!
    var mockStorage: MockHostStorage!
    var mockParser: MockSSHConfigParser!

    override func setUp() {
        mockStorage = MockHostStorage()
        mockParser = MockSSHConfigParser()
        viewModel = HostListViewModel(storage: mockStorage, configParser: mockParser)
    }

    func testLoadHosts() throws {
        mockStorage.hosts = [
            SSHHost(name: "s1", hostname: "10.0.0.1", username: "root"),
            SSHHost(name: "s2", hostname: "10.0.0.2", username: "user"),
        ]

        try viewModel.loadHosts()

        XCTAssertEqual(viewModel.hosts.count, 2)
        guard viewModel.hosts.count == 2 else { return }
        XCTAssertEqual(viewModel.hosts[0].name, "s1")
    }

    func testAddSSHHost() throws {
        let host = SSHHost(name: "new", hostname: "new.com", username: "u")
        try viewModel.addHost(host)

        XCTAssertEqual(viewModel.hosts.count, 1)
        XCTAssertEqual(mockStorage.saveHostsCallCount, 1)
    }

    func testDeleteSSHHost() throws {
        let host = SSHHost(name: "del", hostname: "del.com", username: "u")
        mockStorage.hosts = [host]
        try viewModel.loadHosts()

        try viewModel.deleteHost(host)

        XCTAssertTrue(viewModel.hosts.isEmpty)
        XCTAssertEqual(mockStorage.saveHostsCallCount, 1)
    }

    func testImportSSHConfig() throws {
        let imported = SSHHost(name: "imported", hostname: "imp.com", username: "imp")
        mockParser.parseResult = [imported]

        try viewModel.importSSHConfig("Host imported\n  HostName imp.com\n  User imp")

        XCTAssertEqual(mockParser.parseCallCount, 1)
        XCTAssertEqual(viewModel.hosts.count, 1)
        guard viewModel.hosts.count == 1 else { return }
        XCTAssertEqual(viewModel.hosts[0].name, "imported")
        XCTAssertEqual(mockStorage.saveHostsCallCount, 1)
    }
}
