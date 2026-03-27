# Handoff: 투명한 재연결 시스템 (2026-03-27)

## 구현 완료

### tmux 자동 감지 + 설치
- SSH 연결 시 서버에서 tmux 자동 검색 (`which`, `/usr/bin`, `/usr/local/bin`, `/opt/homebrew/bin`, `~/.local/bin`)
- 없으면 사용자에게 "Enable Session Protection?" 다이얼로그
- Linux: static binary를 `~/.local/bin/tmux`에 배포 (sudo 불필요, ~0.6MB)
- macOS: `brew install tmux` (sudo 불필요)
- **파일**: `ShellDeck/Services/SessionReconnector.swift`

### tmux 자동 래핑
- 첫 연결 시 `tmux new-session -A -s sd_{hostId}` 자동 실행
- 사용자는 tmux를 직접 관리할 필요 없음
- tmux 상태바는 터미널 하단에 표시됨

### 자동 재연결
- `UIApplication.didBecomeActiveNotification` 감지
- 연결이 끊겼으면 자동 SSH 재연결 + tmux reattach
- 재연결 중 "Reconnecting..." 오버레이 표시
- 터미널 버퍼 리셋 (`resetToInitialState`) 후 재연결 — 화면 겹침 방지
- tmux가 없으면 재연결 안 함 (재연결해도 새 셸이라 의미 없음)

### 호스트 편집
- 목록에서 길게 누르면 Edit/Delete 컨텍스트 메뉴
- 기존 호스트 정보 프리필 (이름, 호스트, 포트, 인증 방식 등)
- 편집 시 기존 ID와 키체인 데이터 유지

## 시뮬레이터 검증 결과
- tmux 자동 감지: **OK** (alfred `/opt/homebrew/bin/tmux` 발견)
- tmux 세션 시작: **OK** (`sd_DAC01BD3` 세션 생성)
- SSH 강제 끊기 후 재연결: **OK** (새 SSH + tmux new-session -A)
- tmux 화면 복원: **미검증** — `kill -9`로 끊으면 tmux도 죽음. 실제 iOS 백그라운드에서는 서버 tmux가 살아있으므로 복원 가능.

## 실기기에서 검증해야 할 것

1. **앱 백그라운드 → 30초+ 대기 → 포그라운드 복귀**
   - "Reconnecting..." 오버레이 표시되는지
   - tmux reattach로 이전 화면이 복원되는지
   - 실행 중이던 프로그램(vim, htop 등)이 살아있는지

2. **네트워크 전환 (Wi-Fi → LTE)**
   - SSH 끊김 감지 → 재연결 시도되는지

3. **tmux static binary 배포 (Linux 서버)**
   - 아직 macOS(alfred)에서만 테스트
   - Linux 서버에서 `~/.local/bin/tmux` 배포 동작 확인 필요

## 알려진 이슈

| 이슈 | 파일 | 설명 |
|------|------|------|
| tmux 명령이 화면에 노출됨 | `TerminalRepresentable.swift:135` | `clear` 타이밍이 tmux 시작 전. exec으로 tmux를 직접 시작하는 방식으로 변경 필요 |
| macOS static tmux 불가 | `SessionReconnector.swift` | Apple이 static linking 미지원. macOS 서버는 brew 설치만 가능 |
| 재연결 무한 루프 가능성 | `TerminalRepresentable.swift:190` | `isReconnecting` 플래그로 방지했지만, 서버가 완전히 다운된 경우 계속 실패할 수 있음. 재시도 횟수 제한 추가 필요 |
| 재연결 시 인증 재수행 | `TerminalRepresentable.swift:79` | 매번 키체인에서 키/비밀번호를 읽어 재인증. 현재는 문제 없지만 2FA 서버에서는 실패 가능 |

## 다음 작업

| 우선순위 | 항목 | 비고 |
|:---:|------|------|
| 1 | **실기기 테스트** | 재연결 + tmux 복원의 실제 동작 확인. Apple Developer 인증서 필요 |
| 2 | **tmux 명령 숨기기** | PTY에 직접 타이핑 대신, SSH exec 또는 shell -c로 tmux 시작 |
| 3 | **재시도 횟수 제한** | 3회 실패 시 에러 표시 + 수동 재연결 버튼 |
| 4 | **한국어 IME** | SwiftTerm iOS 입력 처리 조사 |
| 5 | **Host Key 검증** | `.acceptAnything()` → TOFU 다이얼로그 |
| 6 | **Mosh UDP 검증** | 라우터 UDP 포트포워딩 후 |
