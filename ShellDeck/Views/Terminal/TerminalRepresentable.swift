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

final class ShellTerminalViewController: UIViewController, TerminalViewDelegate {
    private let host: SSHHost
    private(set) var terminalView: TerminalView!
    private var onStateChange: ((ConnectionState) -> Void)?

    // SSH
    private var client: SSHClient?
    private var writer: TTYStdinWriter?
    private var isConnected = false

    // Mosh
    private var moshSession: MoshSession?
    private var isMosh: Bool { host.useMosh }

    // 재연결 시스템
    private var reconnector: SessionReconnector!
    private var reconnectOverlay: UIView?
    private var cachedImageView: UIImageView?

    /// SessionReconnector에서 스냅샷용으로 접근
    var terminalViewForSnapshot: UIView? { terminalView }

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

        reconnector = SessionReconnector(host: host, viewController: self)

        Task {
            if isMosh {
                await connectMosh()
            } else {
                await connectSSH(isReconnect: false)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        terminalView.becomeFirstResponder()
    }

    // MARK: - SSH 연결

    private func connectSSH(isReconnect: Bool) async {
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
            let newClient = try await SSHClient.connect(to: settings)
            self.client = newClient
            self.isConnected = true
            onStateChange?(.connected)

            // 첫 연결 시 tmux 감지 + 자동 설치
            if !isReconnect {
                let result = await reconnector.setupTmux(
                    execute: { [weak self] cmd in
                        guard let client = self?.client else { throw SSHSessionError.notConnected }
                        let output = try await client.executeCommand(cmd)
                        return String(buffer: output)
                    },
                    onPrompt: { [weak self] in
                        await self?.promptTmuxInstall() ?? false
                    }
                )
                switch result {
                case .found(let path):
                    print("[tmux] Using existing: \(path)")
                case .installed(let path):
                    print("[tmux] Newly installed: \(path)")
                case .userDeclined:
                    print("[tmux] User declined — plain SSH")
                case .failed(let reason):
                    print("[tmux] Setup failed: \(reason) — plain SSH")
                }
            }

            let cols = await MainActor.run { terminalView.getTerminal().cols }
            let rows = await MainActor.run { terminalView.getTerminal().rows }

            try await newClient.withPTY(
                .init(wantReply: true, term: "xterm-256color",
                      terminalCharacterWidth: cols, terminalRowHeight: rows,
                      terminalPixelWidth: 0, terminalPixelHeight: 0,
                      terminalModes: .init([:]))
            ) { [weak self] inbound, writer in
                guard let self = self else { return }
                self.writer = writer

                // tmux 자동 시작 — 명령을 숨기기 위해 터미널 클리어
                if let tmuxCmd = self.reconnector.tmuxStartCommand() {
                    print("[Reconnect] \(isReconnect ? "Reattaching" : "Starting") tmux session...")
                    // 먼저 터미널 출력 잠깐 무시하고 tmux 시작
                    try await writer.write(ByteBuffer(string: tmuxCmd))
                    // tmux가 시작되면 화면이 리셋됨 — 0.5초 후 clear로 깔끔하게
                    try await Task.sleep(nanoseconds: 500_000_000)
                    try await writer.write(ByteBuffer(string: "clear\n"))
                }

                // 재연결 오버레이 제거
                if isReconnect {
                    await MainActor.run {
                        self.hideReconnectOverlay()
                    }
                }

                for try await chunk in inbound {
                    if case .stdout(let buf) = chunk {
                        let bytes = Array(buf.readableBytesView)
                        await MainActor.run {
                            self.terminalView.feed(byteArray: ArraySlice(bytes))
                        }
                    }
                }
            }

            // 여기 도달 = 세션 종료 (정상 또는 비정상)
            self.isConnected = false
            try? await newClient.close()
            onStateChange?(.disconnected)
        } catch {
            self.isConnected = false
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

    // MARK: - 재연결

    private var isReconnecting = false

    func checkAndReconnect() {
        guard !isMosh, !isConnected, !isReconnecting else { return }
        guard reconnector.tmuxAvailable else { return } // tmux 없으면 재연결 의미 없음

        isReconnecting = true
        print("[Reconnect] Connection lost — reconnecting...")
        showReconnectOverlay()

        // 터미널 버퍼 리셋 — 겹침 방지
        terminalView.getTerminal().resetToInitialState()

        Task {
            await connectSSH(isReconnect: true)
            isReconnecting = false
        }
    }

    private func showReconnectOverlay() {
        guard reconnectOverlay == nil else { return }

        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear

        // 캐시된 스크린샷 표시
        if let screenshot = reconnector.cachedScreenshot {
            let imgView = UIImageView(image: screenshot)
            imgView.frame = overlay.bounds
            imgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imgView.contentMode = .scaleAspectFill
            overlay.addSubview(imgView)
            self.cachedImageView = imgView
        }

        // 반투명 오버레이 + Reconnecting 텍스트
        let dimView = UIView(frame: overlay.bounds)
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.addSubview(dimView)

        let label = UILabel()
        label.text = "Reconnecting..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -12),
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 8),
        ])

        view.addSubview(overlay)
        self.reconnectOverlay = overlay
    }

    private func hideReconnectOverlay() {
        UIView.animate(withDuration: 0.3) {
            self.reconnectOverlay?.alpha = 0
        } completion: { _ in
            self.reconnectOverlay?.removeFromSuperview()
            self.reconnectOverlay = nil
            self.cachedImageView = nil
        }
    }

    // MARK: - tmux 설치 프롬프트

    @MainActor
    private func promptTmuxInstall() async -> Bool {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: "Enable Session Protection?",
                message: "tmux keeps your session alive even if the connection drops. Install it on the server? (No root required)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Install", style: .default) { _ in
                continuation.resume(returning: true)
            })
            alert.addAction(UIAlertAction(title: "Not Now", style: .cancel) { _ in
                continuation.resume(returning: false)
            })
            self.present(alert, animated: true)
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
