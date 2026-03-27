import Foundation
import UIKit

/// 투명한 재연결 시스템
/// - tmux 자동 감지/설치
/// - 백그라운드 진입 시 터미널 화면 스냅샷
/// - 포그라운드 복귀 시 자동 재연결 + tmux reattach
final class SessionReconnector {

    private let host: SSHHost
    private weak var viewController: ShellTerminalViewController?

    var tmuxSessionName: String { "sd_\(host.id.uuidString.prefix(8))" }

    private(set) var tmuxAvailable = false
    private(set) var tmuxPath: String?
    private(set) var cachedScreenshot: UIImage?
    private(set) var remoteOS: String? // "Linux" or "Darwin"

    init(host: SSHHost, viewController: ShellTerminalViewController) {
        self.host = host
        self.viewController = viewController
        observeAppLifecycle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - tmux 감지 + 자동 설치

    enum TmuxSetupResult {
        case found(path: String)
        case installed(path: String)
        case userDeclined
        case failed(String)
    }

    /// SSH 연결 후 tmux를 찾거나 설치.
    /// onPrompt: 사용자에게 설치 여부를 물어보는 콜백
    func setupTmux(
        execute: (String) async throws -> String,
        onPrompt: () async -> Bool
    ) async -> TmuxSetupResult {

        // 1. OS 확인
        if let os = try? await execute("uname -s") {
            remoteOS = os.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        print("[tmux] Remote OS: \(remoteOS ?? "unknown")")

        // 2. tmux 찾기
        let searchPaths = [
            "which tmux 2>/dev/null",
            "test -x /usr/bin/tmux && echo /usr/bin/tmux",
            "test -x /usr/local/bin/tmux && echo /usr/local/bin/tmux",
            "test -x /opt/homebrew/bin/tmux && echo /opt/homebrew/bin/tmux",
            "test -x ~/.local/bin/tmux && echo ~/.local/bin/tmux",
        ]

        for cmd in searchPaths {
            if let result = try? await execute(cmd) {
                let path = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !path.isEmpty && path.hasPrefix("/") || path.hasPrefix("~") {
                    let resolvedPath = path.hasPrefix("~")
                        ? path // 셸이 확장해줌
                        : path
                    tmuxAvailable = true
                    tmuxPath = resolvedPath
                    print("[tmux] Found at: \(resolvedPath)")
                    return .found(path: resolvedPath)
                }
            }
        }

        // 3. tmux 없음 — 설치 제안
        print("[tmux] Not found, prompting user...")
        let userAccepted = await onPrompt()
        guard userAccepted else {
            print("[tmux] User declined installation")
            return .userDeclined
        }

        // 4. 설치
        return await installTmux(execute: execute)
    }

    private func installTmux(execute: (String) async throws -> String) async -> TmuxSetupResult {
        guard let os = remoteOS else { return .failed("Unknown OS") }

        if os == "Darwin" {
            return await installTmuxMacOS(execute: execute)
        } else {
            return await installTmuxLinux(execute: execute)
        }
    }

    /// macOS: brew install tmux (sudo 불필요)
    private func installTmuxMacOS(execute: (String) async throws -> String) async -> TmuxSetupResult {
        print("[tmux] Installing via Homebrew on macOS...")
        do {
            // brew 찾기
            let brewPath = try await execute(
                "test -x /opt/homebrew/bin/brew && echo /opt/homebrew/bin/brew || " +
                "(test -x /usr/local/bin/brew && echo /usr/local/bin/brew || echo '')"
            )
            let brew = brewPath.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !brew.isEmpty else {
                return .failed("Homebrew not found on remote macOS")
            }

            _ = try await execute("\(brew) install tmux 2>&1")

            // 설치 확인
            let tmux = try await execute("test -x /opt/homebrew/bin/tmux && echo /opt/homebrew/bin/tmux || (test -x /usr/local/bin/tmux && echo /usr/local/bin/tmux)")
            let path = tmux.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !path.isEmpty else { return .failed("tmux install failed") }

            tmuxAvailable = true
            tmuxPath = path
            print("[tmux] Installed at: \(path)")
            return .installed(path: path)
        } catch {
            return .failed("brew install failed: \(error.localizedDescription)")
        }
    }

    /// Linux: static binary를 ~/.local/bin/에 배포
    private func installTmuxLinux(execute: (String) async throws -> String) async -> TmuxSetupResult {
        print("[tmux] Deploying static binary on Linux...")
        do {
            // 아키텍처 확인
            let arch = try await execute("uname -m")
            let archStr = arch.trimmingCharacters(in: .whitespacesAndNewlines)

            let binaryName: String
            switch archStr {
            case "x86_64", "amd64":
                binaryName = "tmux-linux-amd64-stripped.gz"
            case "aarch64", "arm64":
                binaryName = "tmux-linux-arm64-stripped.gz"
            default:
                return .failed("Unsupported architecture: \(archStr)")
            }

            // GitHub에서 직접 다운로드
            let url = "https://github.com/mjakob-gh/build-static-tmux/releases/latest/download/\(binaryName)"
            let installScript = """
            mkdir -p ~/.local/bin && \
            curl -fsSL '\(url)' | gunzip > ~/.local/bin/tmux && \
            chmod +x ~/.local/bin/tmux && \
            echo TMUX_INSTALLED
            """

            let result = try await execute(installScript)
            guard result.contains("TMUX_INSTALLED") else {
                return .failed("Download/install failed")
            }

            tmuxAvailable = true
            tmuxPath = "~/.local/bin/tmux"
            print("[tmux] Static binary installed at ~/.local/bin/tmux")
            return .installed(path: "~/.local/bin/tmux")
        } catch {
            return .failed("Static tmux deploy failed: \(error.localizedDescription)")
        }
    }

    // MARK: - tmux 명령 생성

    /// PTY에서 실행할 tmux 시작 명령
    func tmuxStartCommand() -> String? {
        guard let path = tmuxPath else { return nil }
        // -A: 있으면 attach, 없으면 new
        return "\(path) new-session -A -s \(tmuxSessionName)\n"
    }

    // MARK: - 화면 캐시

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    @objc private func appWillResignActive() {
        guard let termView = viewController?.terminalViewForSnapshot else { return }
        let renderer = UIGraphicsImageRenderer(bounds: termView.bounds)
        cachedScreenshot = renderer.image { ctx in
            termView.layer.render(in: ctx.cgContext)
        }
        print("[Reconnect] Screen cached")
    }

    @objc private func appDidBecomeActive() {
        viewController?.checkAndReconnect()
    }
}
