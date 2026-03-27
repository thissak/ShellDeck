# ShellDeck — iOS SSH Terminal App

## Build

```bash
# SPM (unit tests only)
swift test

# Xcode (full iOS app)
xcodegen generate
xcodebuild -project ShellDeck.xcodeproj -scheme ShellDeck \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Integration tests (requires SSH server)
SHELLDECK_SSH_TEST=1 swift test --filter SSHSessionIntegrationTests
```

## Code Style
- Swift 5, iOS 17+
- MVVM + SessionProtocol (SSH/Mosh 공통 인터페이스)
- SwiftUI for views, UIKit for terminal (SwiftTerm TerminalView)
- Protocols for all services → Mock-based unit testing

## Dependencies
- **Citadel** (SPM) — SSH client (SwiftNIO SSH wrapper)
- **SwiftTerm** (SPM) — Terminal emulator
- **KeychainAccess** (SPM) — Keychain wrapper
- **mosh.xcframework** (manual) — Mosh client (blinksh/mosh-apple, GPLv3)
- **Protobuf_C_.xcframework** (manual) — Mosh dependency

## Forbidden
- Do NOT switch to SwiftNIO SSH directly (RSA/keyboard-interactive 미지원)
- Do NOT switch to SwiftSH/libssh2 (의존성 깨짐, 빌드 불가)
- Do NOT auto-fallback Mosh→SSH silently (사용자에게 명시적 확인 필요)
