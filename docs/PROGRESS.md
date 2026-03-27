# ShellDeck Progress

## Phase 1: Foundation — DONE
- [x] Models (SSHHost, SSHKey, KnownHost, ConnectionState)
- [x] Protocols (SessionProtocol, KeychainService, HostKeyService, HostStorage, SSHConfigParser)
- [x] Mocks + 57 unit tests (all green)
- [x] MoshBootstrap parser

## Phase 2: SSH Connection — DONE
- [x] Citadel SSH 연결 (SwiftSH/libssh2 빌드 불가로 전환)
- [x] Ed25519 OpenSSH 키 파서
- [x] PTY 인터랙티브 셸 검증 (macOS + iOS)
- [x] 통합 테스트 3개 (alfred 서버)

## Phase 3: Terminal App — DONE
- [x] SwiftTerm ↔ Citadel PTY 브릿지 (macOS 데모)
- [x] iOS Xcode 프로젝트 (xcodegen)
- [x] 호스트 목록 UI (추가, 삭제, 최근 연결순 정렬)
- [x] 호스트 추가 폼 (비밀번호/키 인증)
- [x] 터미널 전체화면 뷰
- [x] 프로토콜 뱃지 (SSH/MOSH)

## Phase 4: Mosh — IN PROGRESS
- [x] mosh-apple xcframework 통합 (빌드 성공)
- [x] MoshSession 구현 (SSH 부팅 → mosh_main)
- [x] Mosh 실패 시 SSH fallback 다이얼로그
- [x] mosh-server 방화벽 허용 (alfred)
- [ ] UDP 포트포워딩 (TCP→UDP 변경 필요)
- [ ] Mosh 실제 연결 검증

## Phase 5: Polish — TODO
- [ ] 한국어 IME 입력 수정
- [ ] 호스트 편집 UI
- [ ] 실기기(iPhone) 배포 테스트
- [ ] Host key verification (TOFU) UI
- [ ] iCloud 동기화

## Phase 6: SFTP — TODO
- [ ] Citadel SFTP API 연동
- [ ] 파일 브라우저 UI
