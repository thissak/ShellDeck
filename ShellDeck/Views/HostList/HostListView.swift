import SwiftUI

struct HostListView: View {
    @State private var hosts: [SSHHost] = []
    @State private var showAddHost = false
    @State private var selectedHost: SSHHost?
    @State private var editingHost: SSHHost?

    private let container = DependencyContainer.shared

    var body: some View {
        NavigationStack {
            Group {
                if hosts.isEmpty {
                    ContentUnavailableView(
                        "No Hosts",
                        systemImage: "server.rack",
                        description: Text("Tap + to add your first SSH server")
                    )
                } else {
                    List {
                        ForEach(hosts) { host in
                            Button {
                                selectedHost = host
                            } label: {
                                HostRowView(host: host)
                            }
                            .contextMenu {
                                Button {
                                    editingHost = host
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    if let idx = hosts.firstIndex(where: { $0.id == host.id }) {
                                        deleteHost(at: IndexSet(integer: idx))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: deleteHost)
                    }
                }
            }
            .navigationTitle("ShellDeck")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddHost = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHost) {
                HostFormView { newHost in
                    hosts.append(newHost)
                    try? container.hostStorage.saveHosts(hosts)
                }
            }
            .sheet(item: $editingHost) { host in
                HostFormView(editingHost: host) { updated in
                    if let idx = hosts.firstIndex(where: { $0.id == updated.id }) {
                        hosts[idx] = updated
                    }
                    try? container.hostStorage.saveHosts(hosts)
                }
            }
            .fullScreenCover(item: $selectedHost) { host in
                TerminalContainerView(host: host) {
                    // 연결 종료 시 lastConnectedAt 업데이트
                    if let idx = hosts.firstIndex(where: { $0.id == host.id }) {
                        hosts[idx].lastConnectedAt = Date()
                        try? container.hostStorage.saveHosts(hosts)
                    }
                    selectedHost = nil
                }
            }
            .onAppear {
                hosts = (try? container.hostStorage.loadHosts()) ?? []
                // 최근 연결 순 정렬
                hosts.sort { ($0.lastConnectedAt ?? .distantPast) > ($1.lastConnectedAt ?? .distantPast) }
            }
        }
    }

    private func deleteHost(at offsets: IndexSet) {
        // 관련 키체인 데이터도 삭제
        for idx in offsets {
            let host = hosts[idx]
            try? container.keychainService.deletePassword(for: host.id)
            if case .key(let keyId) = host.authMethod {
                try? container.keychainService.deletePrivateKey(for: keyId)
            }
        }
        hosts.remove(atOffsets: offsets)
        try? container.hostStorage.saveHosts(hosts)
    }
}

struct HostRowView: View {
    let host: SSHHost

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(host.name)
                        .font(.headline)
                    if host.useMosh {
                        Text("MOSH")
                            .font(.caption2).bold()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    }
                    switch host.authMethod {
                    case .key:
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    case .password:
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    case .agent:
                        Image(systemName: "person.badge.key.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                Text(verbatim: "\(host.username)@\(host.hostname):\(host.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let last = host.lastConnectedAt {
                Text(last, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
