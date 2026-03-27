import XCTest
@testable import ShellDeck

final class TerminalViewModelTests: XCTestCase {

    var viewModel: TerminalViewModel!
    var mockSession: MockSession!

    override func setUp() {
        mockSession = MockSession()
        viewModel = TerminalViewModel(session: mockSession)
    }

    func testConnect() async throws {
        try await viewModel.connect()

        XCTAssertEqual(mockSession.connectCallCount, 1)
        XCTAssertEqual(viewModel.state, .connected)
    }

    func testConnectFailure() async {
        mockSession.connectError = NSError(domain: "test", code: 1)

        do {
            try await viewModel.connect()
            XCTFail("Expected error")
        } catch {
            if case .error = viewModel.state {
                // Error state set correctly — message is locale-dependent
            } else {
                XCTFail("Expected error state, got \(viewModel.state)")
            }
        }
    }

    func testStateChangeCallback() {
        var receivedStates: [ConnectionState] = []
        viewModel.onStateChange = { state in
            receivedStates.append(state)
        }

        mockSession.setState(.connecting)
        mockSession.setState(.connected)

        XCTAssertEqual(receivedStates, [.connecting, .connected])
    }

    func testHandleTerminalData() throws {
        let data = Data("ls -la\n".utf8)
        try viewModel.handleTerminalInput(data)

        XCTAssertEqual(mockSession.writtenData.count, 1)
        XCTAssertEqual(mockSession.writtenData[0], data)
    }

    func testHandleSessionOutput() {
        var feedData: [Data] = []
        viewModel.onFeedTerminal = { data in
            feedData.append(data)
        }

        let output = Data("total 42\n".utf8)
        mockSession.simulateData(output)

        XCTAssertEqual(feedData.count, 1)
        XCTAssertEqual(feedData[0], output)
    }

    func testDisconnect() {
        viewModel.disconnect()

        XCTAssertEqual(mockSession.disconnectCallCount, 1)
        XCTAssertEqual(viewModel.state, .disconnected)
    }
}
