import SwiftUI

struct TerminalContainerView: View {
    let host: SSHHost
    let onDisconnect: () -> Void

    @State private var connectionState: ConnectionState = .disconnected
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TerminalRepresentable(host: host, onStateChange: { state in
                connectionState = state
                if case .error(let msg) = state {
                    errorMessage = msg
                }
            })
            .ignoresSafeArea(.keyboard)

            // 연결 상태 오버레이
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
                .background(.ultraThinMaterial.opacity(0.3))
                .background(.black.opacity(0.5))
                .cornerRadius(12)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                onDisconnect()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
        }
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
        case .connecting: return host.useMosh ? "Starting Mosh..." : "Connecting..."
        case .authenticating: return "Authenticating..."
        default: return ""
        }
    }
}
