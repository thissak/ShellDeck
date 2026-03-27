import SwiftUI

struct TerminalContainerView: View {
    let host: SSHHost
    let onDisconnect: () -> Void

    @State private var connectionState: ConnectionState = .disconnected
    @State private var errorMessage: String?
    @State private var showMoshFallback = false
    @State private var useSSHFallback = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TerminalRepresentable(
                host: useSSHFallback ? hostWithSSH : host,
                onStateChange: { state in
                    connectionState = state
                    if case .error(let msg) = state {
                        if host.useMosh && !useSSHFallback {
                            showMoshFallback = true
                        } else {
                            errorMessage = msg
                        }
                    }
                }
            )
            .ignoresSafeArea(.keyboard)
            .id(useSSHFallback ? "ssh" : "mosh") // 뷰 재생성용

            if connectionState == .connecting || connectionState == .authenticating {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text(statusText)
                        .foregroundStyle(.white)
                        .font(.subheadline)
                    Text(verbatim: "\(host.username)@\(host.hostname):\(host.port)")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.caption)
                }
                .padding(24)
                .background(.black.opacity(0.7))
                .cornerRadius(12)
            }

        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                if connectionState == .connected {
                    Text(useSSHFallback || !host.useMosh ? "SSH" : "MOSH")
                        .font(.caption2).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(host.useMosh && !useSSHFallback ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                        .foregroundStyle(host.useMosh && !useSSHFallback ? .green : .blue)
                        .cornerRadius(4)
                }
                Button {
                    onDisconnect()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
        }
        // Mosh 실패 → SSH fallback 제안
        .alert("Mosh Connection Failed", isPresented: $showMoshFallback) {
            Button("Connect with SSH") {
                useSSHFallback = true
            }
            Button("Cancel", role: .cancel) {
                onDisconnect()
            }
        } message: {
            Text("Could not establish Mosh connection. This usually means UDP ports 60000-61000 are blocked.\n\nConnect using SSH instead?")
        }
        // 일반 에러
        .alert("Connection Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil; onDisconnect() } }
        )) {
            Button("OK") { onDisconnect() }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var statusText: String {
        switch connectionState {
        case .connecting: return host.useMosh && !useSSHFallback ? "Starting Mosh..." : "Connecting..."
        case .authenticating: return "Authenticating..."
        default: return ""
        }
    }

    /// Mosh OFF 버전의 같은 호스트
    private var hostWithSSH: SSHHost {
        SSHHost(
            id: host.id,
            name: host.name,
            hostname: host.hostname,
            port: host.port,
            username: host.username,
            authMethod: host.authMethod,
            useMosh: false,
            jumpHost: host.jumpHost,
            localForwards: host.localForwards,
            remoteForwards: host.remoteForwards,
            createdAt: host.createdAt,
            lastConnectedAt: host.lastConnectedAt
        )
    }
}
