import Foundation

final class TerminalViewModel {

    private let session: SessionProtocol
    private(set) var state: ConnectionState = .disconnected
    var onStateChange: ((ConnectionState) -> Void)?
    var onFeedTerminal: ((Data) -> Void)?

    init(session: SessionProtocol) {
        self.session = session
        session.onStateChange = { [weak self] newState in
            self?.state = newState
            self?.onStateChange?(newState)
        }
        session.onData = { [weak self] data in
            self?.onFeedTerminal?(data)
        }
    }

    func connect() async throws {
        do {
            try await session.connect()
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    func disconnect() {
        session.disconnect()
    }

    func handleTerminalInput(_ data: Data) throws {
        try session.write(data)
    }
}
