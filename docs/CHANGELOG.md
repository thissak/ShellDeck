# Changelog

## 2026-03-27

### Initial Release (c2ff834)
- SSH 터미널 앱 기본 구조 완성
- Citadel SSH 연결 + SwiftTerm 터미널 렌더링
- Ed25519 키 인증 + 비밀번호 인증
- 호스트 관리 (추가/삭제)
- 57 단위 테스트 + 3 통합 테스트
- SessionProtocol 아키텍처 (SSH/Mosh 공통)

### Mosh Integration (a3e0ad4)
- mosh-apple xcframework 통합
- MoshSession: SSH 부팅 → mosh_main UDP 연결
- Mosh 실패 시 "SSH로 연결할까요?" fallback 다이얼로그
- 프로토콜 뱃지 (SSH/MOSH) 표시
- 호스트 추가 시 Mosh UDP 포트 안내

**기술 결정:**
- SwiftSH(libssh2) → Citadel 전환: SwiftSH 의존성(Libssh2Prebuild) 깨져서 빌드 불가
- Mosh fallback: 자동 전환이 아닌 사용자 확인 방식 채택 (Blink/Termius도 자동 fallback 없음)
