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

    let onSave: (SSHHost) -> Void

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

                Section("Options") {
                    Toggle("Use Mosh", isOn: $useMosh)
                }
            }
            .navigationTitle("Add Host")
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

    private func save() {
        let container = DependencyContainer.shared
        let keyId = UUID()

        let authMethod: SSHHost.AuthMethod
        switch authType {
        case .password:
            authMethod = .password
        case .key:
            authMethod = .key(keyId: keyId)
        }

        let host = SSHHost(
            name: name.isEmpty ? hostname : name,
            hostname: hostname,
            port: UInt16(port) ?? 22,
            username: username,
            authMethod: authMethod,
            useMosh: useMosh
        )

        switch authType {
        case .password:
            try? container.keychainService.storePassword(password, for: host.id)
        case .key:
            try? container.keychainService.storePrivateKey(Data(privateKeyText.utf8), for: keyId)
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
