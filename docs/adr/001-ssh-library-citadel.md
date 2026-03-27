# ADR-001: SSH 라이브러리로 Citadel 채택

**Status:** Accepted
**Date:** 2026-03-27

## Context
iOS SSH 터미널 앱에서 SSH 라이브러리 선택이 필요했다. 후보: SwiftNIO SSH, SwiftSH(libssh2), Citadel.

## Decision
**Citadel** (SwiftNIO SSH 위의 고수준 래퍼)을 채택한다.

## Consequences

### SwiftNIO SSH 직접 사용 불가 (팩트)
- RSA 공개키 인증 미지원
- keyboard-interactive 미지원
- OpenSSH 키 파일 로딩 미지원
- iOS 예제/문서 없음, 프리릴리스 (1.0 없음)

### SwiftSH(libssh2) 빌드 불가 (팩트)
- Libssh2Prebuild 패키지의 semver 태그가 깨져 SPM resolve 실패
- 2026-03-27 시점 `swift package resolve` 에러 확인

### Citadel 채택 근거 (팩트)
- SPM resolve + 빌드 성공 (v0.12.0)
- async/await 네이티브 API
- RSA 지원 (Insecure.RSA.PrivateKey)
- Ed25519/ECDSA 지원
- PTY(withPTY) + 명령 실행(executeCommand) API
- 실제 서버(alfred) 접속 검증 완료
