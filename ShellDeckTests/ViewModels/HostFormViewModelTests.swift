import XCTest
@testable import ShellDeck

final class HostFormViewModelTests: XCTestCase {

    var viewModel: HostFormViewModel!

    override func setUp() {
        viewModel = HostFormViewModel()
    }

    func testEmptyHostname_invalid() {
        viewModel.hostname = ""
        viewModel.username = "user"
        viewModel.port = "22"

        XCTAssertFalse(viewModel.isValid)
    }

    func testEmptyUsername_invalid() {
        viewModel.hostname = "example.com"
        viewModel.username = ""
        viewModel.port = "22"

        XCTAssertFalse(viewModel.isValid)
    }

    func testPortZero_invalid() {
        viewModel.hostname = "example.com"
        viewModel.username = "user"
        viewModel.port = "0"

        XCTAssertFalse(viewModel.isValid)
    }

    func testPortOverMax_invalid() {
        viewModel.hostname = "example.com"
        viewModel.username = "user"
        viewModel.port = "65536"

        XCTAssertFalse(viewModel.isValid)
    }

    func testPortNotNumber_invalid() {
        viewModel.hostname = "example.com"
        viewModel.username = "user"
        viewModel.port = "abc"

        XCTAssertFalse(viewModel.isValid)
    }

    func testAllFieldsValid() {
        viewModel.hostname = "example.com"
        viewModel.username = "user"
        viewModel.port = "22"
        viewModel.name = "My Server"

        XCTAssertTrue(viewModel.isValid)
    }

    func testBuildHost() {
        viewModel.hostname = "example.com"
        viewModel.username = "admin"
        viewModel.port = "2222"
        viewModel.name = "Prod"
        viewModel.useMosh = true

        let host = viewModel.buildHost()

        XCTAssertEqual(host.hostname, "example.com")
        XCTAssertEqual(host.username, "admin")
        XCTAssertEqual(host.port, 2222)
        XCTAssertEqual(host.name, "Prod")
        XCTAssertTrue(host.useMosh)
    }
}
