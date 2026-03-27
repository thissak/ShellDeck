import SwiftUI
import SwiftTerm
import Citadel
import Crypto
import NIOCore
import NIOSSH

struct TerminalRepresentable: UIViewControllerRepresentable {
    let host: SSHHost
    var onStateChange: ((ConnectionState) -> Void)?

    func makeUIViewController(context: Context) -> ShellTerminalViewController {
        ShellTerminalViewController(host: host, onStateChange: onStateChange)
    }

    func updateUIViewController(_ uiViewController: ShellTerminalViewController, context: Context) {}
}

/// 단일 TerminalViewController — SessionProtocol (SSH/Mosh) 공통
final class ShellTerminalViewController: UIViewController, TerminalViewDelegate {
    private let host: SSHHost
    private var terminalView: TerminalView!
    private var onStateChange: ((ConnectionState) -> Void)?

    // SSH 모드용
    private var writer: TTYStdinWriter?
    // Mosh 모드용
    private var moshSession: MoshSession?
    // 현재 모드
    private var isMosh: Bool { host.useMosh }

    init(host: SSHHost, onStateChange: ((ConnectionState) -> Void)?) {
        self.host = host
        self.onStateChange = onStateChange
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        terminalView = TerminalView(frame: view.bounds)
        terminalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        terminalView.terminalDelegate = self
        view.addSubview(terminalView)

        Task {
            if isMosh {
                await connectMosh()
            } else {
                await connectSSH()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        terminalView.becomeFirstResponder()
    }

    // MARK: - SSH 연결

    private func connectSSH() async {
        onStateChange?(.connecting)
        do {
            let authMethod = try buildAuthMethod()
            onStateChange?(.authenticating)

            let settings = SSHClientSettings(
                host: host.hostname,
                port: Int(host.port),
                authenticationMethod: { authMethod },
                hostKeyValidator: .acceptAnything()
            )
            let client = try await SSHClient.connect(to: settings)
            onStateChange?(.connected)

            let cols = await MainActor.run { terminalView.getTerminal().cols }
            let rows = await MainActor.run { terminalView.getTerminal().rows }

            try await client.withPTY(
                .init(wantReply: true, term: "xterm-256color",
                      terminalCharacterWidth: cols, terminalRowHeight: rows,
                      terminalPixelWidth: 0, terminalPixelHeight: 0,
                      terminalModes: .init([:]))
            ) { [weak self] inbound, writer in
                self?.writer = writer
                for try await chunk in inbound {
                    if case .stdout(let buf) = chunk {
                        let bytes = Array(buf.readableBytesView)
                        await MainActor.run {
                            self?.terminalView.feed(byteArray: ArraySlice(bytes))
                        }
                    }
                }
            }
            try? await client.close()
            onStateChange?(.disconnected)
        } catch {
            onStateChange?(.error(error.localizedDescription))
        }
    }

    // MARK: - Mosh 연결

    private func connectMosh() async {
        let container = DependencyContainer.shared
        let session = MoshSession(host: host, keychainService: container.keychainService)
        self.moshSession = session

        session.onStateChange = { [weak self] state in
            self?.onStateChange?(state)
        }
        session.onData = { [weak self] data in
            DispatchQueue.main.async {
                self?.terminalView.feed(byteArray: ArraySlice([UInt8](data)))
            }
        }

        do {
            try await session.connect()
        } catch {
            onStateChange?(.error(error.localizedDescription))
        }
    }

    // MARK: - Auth

    private func buildAuthMethod() throws -> SSHAuthenticationMethod {
        let container = DependencyContainer.shared
        switch host.authMethod {
        case .password:
            guard let password = try container.keychainService.retrievePassword(for: host.id) else {
                throw SSHSessionError.noCredentials
            }
            return .passwordBased(username: host.username, password: password)
        case .key(let keyId):
            guard let keyData = try container.keychainService.retrievePrivateKey(for: keyId) else {
                throw SSHSessionError.noCredentials
            }
            let keyString = String(data: keyData, encoding: .utf8) ?? ""
            let privateKey = try OpenSSHKeyParser.parseEd25519(from: keyString)
            return .ed25519(username: host.username, privateKey: privateKey)
        case .agent:
            throw SSHSessionError.agentNotSupported
        }
    }

    // MARK: - TerminalViewDelegate

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        if isMosh {
            try? moshSession?.write(Data(data))
        } else {
            guard let w = writer else { return }
            Task { try? await w.write(ByteBuffer(bytes: Array(data))) }
        }
    }

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        if isMosh {
            try? moshSession?.resizePTY(cols: newCols, rows: newRows)
        } else {
            guard let w = writer else { return }
            Task { try? await w.changeSize(cols: newCols, rows: newRows, pixelWidth: 0, pixelHeight: 0) }
        }
    }

    func setTerminalTitle(source: TerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func scrolled(source: TerminalView, position: Double) {}
    func requestOpenLink(source: TerminalView, link: String, params: [String : String]) {}
    func bell(source: TerminalView) {}
    func clipboardCopy(source: TerminalView, content: Data) {
        UIPasteboard.general.setData(content, forPasteboardType: "public.utf8-plain-text")
    }
    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {}
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
}
