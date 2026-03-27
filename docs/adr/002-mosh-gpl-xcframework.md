# ADR-002: Mosh 통합 — GPLv3 xcframework 채택

**Status:** Accepted
**Date:** 2026-03-27

## Context
Mosh(UDP 기반 세션 유지)가 앱의 핵심 차별점. 통합 방법 3가지: blinksh/mosh-apple(GPLv3), swift-mosh(MIT, 실험적), 자체 구현.

## Decision
**blinksh/mosh-apple xcframework**를 채택한다. 앱 전체 라이선스를 GPLv3으로 한다.

## Consequences
- 앱 소스코드 공개 의무 (GitHub public repo)
- App Store 유료 판매 가능 (COPYING.iOS 예외 조항)
- swift-mosh(MIT)는 v0.1.0, 예측 로컬 에코 미구현으로 부적합
- Mosh 연결 실패 시 SSH fallback — 사용자 확인 후 전환 (자동 아님)
