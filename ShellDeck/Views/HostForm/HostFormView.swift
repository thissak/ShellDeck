import SwiftUI

enum AuthType: String, CaseIterable {
    case password = "Password"
    case key = "Private Key"
}

struct HostFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hostname = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var password = ""
    @State private var privateKeyText = ""
    @State private var authType: AuthType = .password
    @State private var useMosh = false
    @State private var showKeyPasteSheet = false

    /// 편집할 기존 호스트 (nil이면 신규)
    var editingHost: SSHHost?
    let onSave: (SSHHost) -> Void

    private var isEditing: Bool { editingHost != nil }

    private var isValid: Bool {
        guard !hostname.isEmpty, !username.isEmpty,
              let p = UInt16(port), p > 0 else { return false }
        switch authType {
        case .password: return !password.isEmpty
        case .key: return !privateKeyText.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("Name", text: $name, prompt: Text("My Server"))
                    TextField("Hostname", text: $hostname, prompt: Text("192.168.1.1"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    TextField("Username", text: $username, prompt: Text("root"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Authentication") {
                    Picker("Method", selection: $authType) {
                        ForEach(AuthType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch authType {
                    case .password:
                        SecureField("Password", text: $password)
                    case .key:
                        if privateKeyText.isEmpty {
                            Button("Paste Private Key") {
                                if let clip = UIPasteboard.general.string,
                                   clip.contains("BEGIN") {
                                    privateKeyText = clip
                                } else {
                                    showKeyPasteSheet = true
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(.green)
                                Text("Key loaded (\(privateKeyText.count) chars)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Clear") {
                                    privateKeyText = ""
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section {
                    Toggle("Use Mosh", isOn: $useMosh)
                    if useMosh {
                        Label("Requires mosh-server on remote host and UDP ports 60000-61000 open. Falls back to SSH if unavailable.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Options")
                }
            }
            .navigationTitle(isEditing ? "Edit Host" : "Add Host")
            .onAppear { prefillIfEditing() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showKeyPasteSheet) {
                KeyPasteView { key in
                    privateKeyText = key
                }
            }
        }
    }

    private func prefillIfEditing() {
        guard let host = editingHost else { return }
        name = host.name
        hostname = host.hostname
        port = String(host.port)
        username = host.username
        useMosh = host.useMosh
        switch host.authMethod {
        case .password:
            authType = .password
            password = (try? DependencyContainer.shared.keychainService.retrievePassword(for: host.id)) ?? ""
        case .key(let keyId):
            authType = .key
            if let data = try? DependencyContainer.shared.keychainService.retrievePrivateKey(for: keyId) {
                privateKeyText = String(data: data, encoding: .utf8) ?? ""
            }
        case .agent:
            authType = .key
        }
    }

    private func save() {
        let container = DependencyContainer.shared

        // 편집 시 기존 keyId 유지, 신규 시 새 keyId
        let existingKeyId: UUID? = {
            if case .key(let id) = editingHost?.authMethod { return id }
            return nil
        }()
        let keyId = existingKeyId ?? UUID()

        let authMethod: SSHHost.AuthMethod
        switch authType {
        case .password:
            authMethod = .password
        case .key:
            authMethod = .key(keyId: keyId)
        }

        let host = SSHHost(
            id: editingHost?.id ?? UUID(),
            name: name.isEmpty ? hostname : name,
            hostname: hostname,
            port: UInt16(port) ?? 22,
            username: username,
            authMethod: authMethod,
            useMosh: useMosh,
            createdAt: editingHost?.createdAt ?? Date(),
            lastConnectedAt: editingHost?.lastConnectedAt
        )

        switch authType {
        case .password:
            if !password.isEmpty {
                try? container.keychainService.storePassword(password, for: host.id)
            }
        case .key:
            if !privateKeyText.isEmpty {
                try? container.keychainService.storePrivateKey(Data(privateKeyText.utf8), for: keyId)
            }
        }

        onSave(host)
        dismiss()
    }
}

struct KeyPasteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyText = ""
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Paste your private key below")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top)

                TextEditor(text: $keyText)
                    .font(.system(.caption, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
            }
            .navigationTitle("Private Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(keyText)
                        dismiss()
                    }
                    .disabled(!keyText.contains("BEGIN"))
                }
            }
        }
    }
}
