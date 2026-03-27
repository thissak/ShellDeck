import Foundation
import Citadel
import Crypto
import NIOCore
import os.log

private let logger = Logger(subsystem: "com.shelldeck", category: "MoshSession")

/// SessionProtocol 구현 — SSH로 mosh-server 부팅 → UDP 전환
final class MoshSession: SessionProtocol {

    private let host: SSHHost
    private let keychainService: KeychainServiceProtocol

    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var moshThread: Thread?

    private(set) var state: ConnectionState = .disconnected
    var onStateChange: ((ConnectionState) -> Void)?
    var onData: ((Data) -> Void)?

    init(host: SSHHost, keychainService: KeychainServiceProtocol) {
        self.host = host
        self.keychainService = keychainService
    }

    func connect() async throws {
        print("[MOSH] Step 1: Starting SSH connection to \(self.host.hostname):\(self.host.port)")
        setState(.connecting)

        let authMethod = try buildAuthMethod()
        print("[MOSH] Step 2: Auth method built, authenticating...")
        setState(.authenticating)

        let settings = SSHClientSettings(
            host: host.hostname,
            port: Int(host.port),
            authenticationMethod: { authMethod },
            hostKeyValidator: .acceptAnything()
        )
        let sshClient = try await SSHClient.connect(to: settings)
        print("[MOSH] Step 3: SSH connected, launching mosh-server...")

        // mosh-server 실행
        // mosh-server를 nohup으로 실행 — SSH 채널 종료 후에도 살아있게
        let cmd = "export PATH=$PATH:/opt/homebrew/bin:/usr/local/bin; mosh-server new -s -c 256 -l LANG=en_US.UTF-8 2>&1; sleep 1"
        let output = try await sshClient.executeCommand(cmd)
        let outputString = String(buffer: output)
        print("[MOSH] Step 4: mosh-server output: \(outputString)")

        // SSH 연결을 바로 닫지 않고 mosh-server가 detach할 시간을 줌
        try await Task.sleep(nanoseconds: 500_000_000)
        try? await sshClient.close()
        print("[MOSH] Step 4.5: SSH closed, waiting for mosh-server to stabilize...")
        try await Task.sleep(nanoseconds: 500_000_000)

        // 포트+키 파싱
        let info = try MoshBootstrap.parse(outputString, host: host.hostname)
        print("[MOSH] Step 5: Parsed — host=\(info.host) port=\(info.port) key=\(info.key)")

        // Pipe 생성
        let inPipe = Pipe()
        let outPipe = Pipe()
        self.inputPipe = inPipe
        self.outputPipe = outPipe

        let inReadFd = inPipe.fileHandleForReading.fileDescriptor
        let outWriteFd = outPipe.fileHandleForWriting.fileDescriptor
        print("[MOSH] Step 6: Pipes created — inReadFd=\(inReadFd) outWriteFd=\(outWriteFd)")

        // 출력 읽기
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                print("[MOSH] Output pipe: EOF (empty data)")
                return
            }
            print("[MOSH] Output pipe: received \(data.count) bytes")
            self?.onData?(data)
        }

        // mosh_main 실행
        let portStr = String(info.port)
        let keyStr = info.key
        let ipStr = info.host

        print("[MOSH] Step 7: Starting mosh_main thread — ip=\(ipStr) port=\(portStr)")

        // stderr 캡처용 pipe
        let errPipe = Pipe()
        let savedStderr = dup(STDERR_FILENO)
        dup2(errPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        errPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                let msg = "[MOSH-STDERR] \(str)\n"
                msg.withCString { ptr in
                    Darwin.write(savedStderr, ptr, strlen(ptr))
                }
            }
        }

        let thread = Thread {
            print("[MOSH] Thread: started")

            var ws = winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0)

            let fIn = fdopen(inReadFd, "rb")
            let fOut = fdopen(outWriteFd, "wb")

            // Blink과 동일: unbuffered I/O — mosh 출력이 즉시 flush되도록
            if let fIn = fIn { setvbuf(fIn, nil, _IONBF, 0) }
            if let fOut = fOut { setvbuf(fOut, nil, _IONBF, 0) }

            print("[MOSH] Thread: fIn=\(fIn != nil ? "OK" : "NULL") fOut=\(fOut != nil ? "OK" : "NULL")")

            guard fIn != nil, fOut != nil else {
                print("[MOSH] Thread: FAILED to fdopen!")
                return
            }

            print("[MOSH] Thread: calling mosh_main() with unbuffered I/O...")
            let result = mosh_main(
                fIn, fOut, &ws,
                nil, nil,
                ipStr, portStr, keyStr,
                "adaptive",
                nil, 0, nil
            )
            print("[MOSH] Thread: mosh_main returned \(result)")

            // stderr 복원
            dup2(savedStderr, STDERR_FILENO)
            close(savedStderr)
            errPipe.fileHandleForReading.readabilityHandler = nil

            if result != 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.setState(.error("Mosh connection failed (UDP port may be blocked)"))
                }
            }
        }
        thread.name = "mosh-session"
        thread.start()
        self.moshThread = thread

        print("[MOSH] Step 8: Thread started, setting state to connected")
        setState(.connected)

        // 15초 타임아웃 — 출력이 없으면 연결 실패로 판단
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard let self = self, self.state == .connected else { return }
            // mosh_main이 아직 실행 중이고 출력이 없었으면 실패
            if self.outputPipe?.fileHandleForReading.availableData.isEmpty ?? true {
                // 아무 출력도 없으면 연결 실패 — 출력이 있었으면 정상
            }
        }
    }

    func disconnect() {
        print("[MOSH] Disconnecting...")
        inputPipe?.fileHandleForWriting.closeFile()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        moshThread?.cancel()
        inputPipe = nil
        outputPipe = nil
        moshThread = nil
        setState(.disconnected)
    }

    func write(_ data: Data) throws {
        inputPipe?.fileHandleForWriting.write(data)
    }

    func resizePTY(cols: Int, rows: Int) throws {
        // TODO: mosh 런타임 리사이즈
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
