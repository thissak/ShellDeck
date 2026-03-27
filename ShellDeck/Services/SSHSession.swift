import Foundation
import Citadel
import Crypto
import NIOSSH
import NIOCore

final class SSHSession: SessionProtocol {

    private let host: SSHHost
    private let keychainService: KeychainServiceProtocol
    private var client: SSHClient?

    private(set) var state: ConnectionState = .disconnected
    var onStateChange: ((ConnectionState) -> Void)?
    var onData: ((Data) -> Void)?

    init(host: SSHHost, keychainService: KeychainServiceProtocol) {
        self.host = host
        self.keychainService = keychainService
    }

    func connect() async throws {
        setState(.connecting)

        let authMethod = try buildAuthMethod()
        setState(.authenticating)

        let settings = SSHClientSettings(
            host: host.hostname,
            port: Int(host.port),
            authenticationMethod: { authMethod },
            hostKeyValidator: .acceptAnything() // TODO: HostKeyService 연동
        )

        let client = try await SSHClient.connect(to: settings)
        self.client = client
        setState(.connected)
    }

    func disconnect() {
        Task {
            try? await client?.close()
            client = nil
        }
        setState(.disconnected)
    }

    func write(_ data: Data) throws {
        // PTY 세션에서 사용 — withPTY의 writer로 위임
        // 이 메서드는 PTY 통합 시 구현
    }

    func resizePTY(cols: Int, rows: Int) throws {
        // PTY 리사이즈 — Citadel의 PTY API로 위임
    }

    /// 명령 실행 (비인터랙티브)
    func executeCommand(_ command: String) async throws -> String {
        guard let client = client else {
            throw SSHSessionError.notConnected
        }
        let output = try await client.executeCommand(command)
        return String(buffer: output)
    }

    private func buildAuthMethod() throws -> SSHAuthenticationMethod {
        switch host.authMethod {
        case .password:
            guard let password = try keychainService.retrievePassword(for: host.id) else {
                throw SSHSessionError.noCredentials
            }
            return .passwordBased(username: host.username, password: password)

        case .key(let keyId):
            guard let keyData = try keychainService.retrievePrivateKey(for: keyId) else {
                throw SSHSessionError.noCredentials
            }
            let keyString = String(data: keyData, encoding: .utf8) ?? ""
            let privateKey = try OpenSSHKeyParser.parseEd25519(from: keyString)
            return .ed25519(username: host.username, privateKey: privateKey)

        case .agent:
            throw SSHSessionError.agentNotSupported
        }
    }

    private func setState(_ newState: ConnectionState) {
        state = newState
        onStateChange?(newState)
    }
}

enum SSHSessionError: Error {
    case notConnected
    case noCredentials
    case agentNotSupported
}
