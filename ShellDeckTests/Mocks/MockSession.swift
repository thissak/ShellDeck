import Foundation
@testable import ShellDeck

final class MockSession: SessionProtocol {
    var state: ConnectionState = .disconnected
    var onStateChange: ((ConnectionState) -> Void)?
    var onData: ((Data) -> Void)?

    var connectCallCount = 0
    var connectError: Error?
    var disconnectCallCount = 0
    var writtenData: [Data] = []
    var writeError: Error?
    var lastResizeCols: Int?
    var lastResizeRows: Int?

    func connect() async throws {
        connectCallCount += 1
        if let error = connectError { throw error }
        setState(.connected)
    }

    func disconnect() {
        disconnectCallCount += 1
        setState(.disconnected)
    }

    func write(_ data: Data) throws {
        if let error = writeError { throw error }
        writtenData.append(data)
    }

    func resizePTY(cols: Int, rows: Int) throws {
        lastResizeCols = cols
        lastResizeRows = rows
    }

    // Test helpers
    func setState(_ newState: ConnectionState) {
        state = newState
        onStateChange?(newState)
    }

    func simulateData(_ data: Data) {
        onData?(data)
    }
}
