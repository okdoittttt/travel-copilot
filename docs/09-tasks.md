# 작업 목록

> 상태: 초안 (2026-11-08) — 승인 대기
> 기간: MVP 약 12주 (1인, 밀려도 순서는 지킨다)
> 관련 문서: [02-mvp.md](02-mvp.md), [03-dev-process.md](03-dev-process.md), [../security/roadmap.md](../security/roadmap.md)

## 1. 한눈에 보기

| # | 작업 | 주차 | 브랜치 | 기능 명세 | 로드맵 단계 | 선행 |
|---|---|---|---|---|---|---|
| D | 설계 문서 PR | 0 | `docs/design` | — | — | — |
| P | 외부 준비물 (직접) | 0~ | — | — | — | — |
| F0 | 기반 | 1~2 | `chore/foundation` | `features/foundation.md` | 0, 4 | D |
| F1 | 인증 (Google 로그인) | 3~4 | `feat/auth` | `features/auth.md` | 1 | F0, P3 |
| F2 | 여행·멤버 | 5 | `feat/trips` | `features/trips.md` | 2 | F1 |
| F3 | 일정·장소 검색 | 6 | `feat/itinerary` | `features/itinerary.md` | 2 | F2, P3 |
| F4 | 이동시간·지도 | 7 | `feat/routes-map` | `features/routes-map.md` | 2 | F3 |
| F5 | 초대 링크 | 8 | `feat/invites` | `features/invites.md` | 2 | F2, P4 |
| F6 | 동기화·오프라인 일정 | 9 | `feat/sync-offline` | `features/sync-offline.md` | 2, 3 | F3 |
| F7 | 바우처 (서버·온라인) | 10 | `feat/vouchers` | `features/vouchers.md` | 3 | F2 |
| F8 | 바우처 오프라인 | 11 | `feat/vouchers-offline` | `features/vouchers-offline.md` | 3 | F6, F7 |
| F9 | 설정·회원 탈퇴 | 12 | `feat/account` | `features/account.md` | 3, 6 | F7 |
| F10 | 카카오·Apple 로그인 | 11~12 | `feat/auth-kakao-apple` | `features/auth-kakao-apple.md` | 1 | F1, P1·P2 |
| R | 출시 준비 | 12 | `chore/release` | — | 출시 전 점검 | F0~F10 |

- 기능마다 [03-dev-process.md](03-dev-process.md) 4절의 순서(명세 → 승인 → 구현 → 검증 → 보안 점검 → 반영 → PR)를 따른다
- 각 작업의 체크리스트는 명세를 쓰면서 구체화한다. 아래는 범위를 정하는 수준
- 보안 점검 기록: `security/reviews/YYYY-MM-DD-<작업>.md`

## 2. 외부 준비물 (P) — 직접 진행

오래 걸리거나 비용이 드는 것. 해당 작업 시작 전까지 준비.

| # | 항목 | 목적 (없으면 안 되는 것) | 필요한 작업 | 비고 |
|---|---|---|---|---|
| P1 | Apple Developer Program 가입 | iOS 앱을 실기기·TestFlight·앱스토어에 배포할 자격. Apple 로그인, Universal Links도 이 계정의 설정으로만 켤 수 있음 | F5 (Universal Links), F10 (Apple 로그인), R (TestFlight) | 연 $99, 승인에 며칠 걸릴 수 있음 |
| P2 | 카카오 개발자 앱 등록 | 앱이 카카오 로그인을 쓰려면 카카오에 "이 앱"을 등록해 앱 키를 받아야 함. 서버가 검증할 ID 토큰도 여기서 OIDC를 켜야 발급됨 | F10 | OpenID Connect 활성화 필요 |
| P3 | Google Cloud 프로젝트 | 장소 검색(Places)·이동시간(Routes)·지도(Maps SDK) API 키와 과금 계정, Google 로그인용 OAuth 클라이언트 | F1 (Google 로그인), F3·F4 (Places·Routes·Maps) | 결제 계정 연결, **예산 알림·할당량 상한 먼저 설정** (T23) |
| P4 | 도메인 | 앱이 접속할 서버 주소(HTTPS 인증서 발급에 필요), 초대 링크 주소, 딥링크 확인 파일을 둘 곳 | F5 (딥링크, 초대 안내 웹페이지) | 보유 중인 도메인의 서브도메인 사용 (예: `travel.<보유 도메인>`). API·초대 링크·딥링크 파일을 한 서브도메인에 |
| P5 | Google Play Console | Android 앱을 테스터·플레이스토어에 배포할 자격 | R (내부 테스트) | 1회 $25 |
| P6 | 스테이징 호스팅 | 내 컴퓨터 밖, 인터넷에서 접속 가능한 서버. 실기기 테스트와 테스터 배포에 필요 | R (실기기 테스트용 서버) | 운영 호스팅 결정(로드맵 5단계)을 앞당겨야 할 수 있음 |

## 3. 작업 상세

### D. 설계 문서 PR
- [x] 04-architecture, 05-data-model, 06-api, 07-screens, 08-conventions
- [ ] 09-tasks (이 문서) 승인
- [ ] `docs/design` 브랜치 커밋 → push·PR 명령어 전달 → 머지

### F0. 기반 (1~2주)

**서버·인프라**
- [x] `server/`: uv 프로젝트, FastAPI 앱, 설정(pydantic-settings), 전역 예외 핸들러(RFC 9457), JSON 로깅·request_id, `/health`
- [x] SQLAlchemy async 세션, Alembic 초기화
- [x] 테스트 기반: 실제 PostgreSQL 테스트 DB, httpx 클라이언트, respx
- [x] `infra/docker-compose.yml`: 서버, PostgreSQL, Nginx (파일 저장소는 F7)
- [x] Nginx: mkcert 로컬 인증서로 TLS, 요청 크기 제한, 보안 헤더
- [x] `.env.example`, `.gitignore` 점검

**앱**
- [x] `app/`: Flutter 프로젝트, very_good_analysis, 폴더 구조(core/features)
- [x] Riverpod·go_router·dio·freezed·build_runner 설정, l10n(ARB) 설정
- [x] 앱 로거(print 금지 lint), 공통 에러 타입 뼈대
- [x] 환경 구분 (dev/staging/prod — API 주소)
- [x] 로컬 서버 연결 확인 (`/health` 호출) — iOS 시뮬레이터 확인 완료, Android는 SDK 설치 후 확인

**저장소·CI**
- [x] gitleaks pre-commit 훅
- [x] GitHub Actions: `server.yml`, `app.yml`, `security.yml` (액션은 커밋 SHA로 고정, 최소 권한)
- [x] `.github/pull_request_template.md`

**로드맵 연계**: 0단계 (TLS, 비밀값 관리, gitleaks), 4단계 일부 (CI)
**완료 기준**: `docker compose up`으로 HTTPS `/health` 응답, 앱에서 호출 성공, CI 3종 통과

### F1. 인증 — Google 로그인 (3~4주)

소셜 로그인은 Google만 먼저 구현한다. 공급자별 검증 코드를 교체 가능한 구조로 만들어, F10에서 카카오·Apple을 붙일 때 공통 부분(토큰 발급·갱신·폐기)은 손대지 않게 한다.

- [x] 인증 설계 확정 (명세에 포함): 액세스 토큰 형식(JWT vs 불투명), nonce 저장 방식, 공급자 추가 구조
- [x] 테이블: users, social_accounts, refresh_tokens
- [x] `POST /auth/nonce`, `POST /auth/{provider}/login` — ID 토큰 검증 (JWKS 캐시, iss·aud·exp·nonce)
- [x] `POST /auth/refresh` — 토큰 교체, 재사용 감지 시 묶음 폐기
- [x] `POST /auth/logout`, `GET·PATCH /me`
- [x] 인증 의존성 (`current_user`), 요청 횟수 제한 기반
- [x] 앱: S01 시작, S02 로그인 (Google 버튼만), secure storage 토큰 저장, dio 자동 갱신 인터셉터
- [x] 보안 테스트: 위조 토큰, 다른 앱용 토큰(aud), 만료 토큰, nonce 재사용, 리프레시 토큰 재사용, 이메일 같은 다른 공급자 계정이 합쳐지지 않음

**위협**: T01~T05 / **로드맵**: 1단계 전체

### F2. 여행·멤버 (5주)

- [ ] 테이블: trips, trip_members
- [ ] `require_trip_member(role)` 의존성 + **라우트 전수 검사 테스트**
- [ ] 여행 CRUD, 스냅샷 조회 (`GET /trips/{id}` — 이 시점엔 멤버까지만)
- [ ] 멤버 역할 변경·내보내기·나가기·소유권 넘기기
- [ ] 앱: S03 여행 목록, S04 여행 만들기·수정, S05 여행 상세(탭 뼈대), S14 멤버
- [ ] 보안 테스트: IDOR, viewer의 수정 시도, 내보낸 멤버 재접근, owner 중복 불가

**위협**: T06·T07·T08·T29 / **로드맵**: 2단계 (인가)

### F3. 일정·장소 검색 (6주)

- [ ] 테이블: itinerary_items
- [ ] 일정 항목 CRUD, 하루 순서 변경 (version 검사), 스냅샷에 일정 포함
- [ ] Google Places 클라이언트: 자동완성·상세, 필드 마스크, 세션 토큰, 타임아웃, 사용자별 호출 제한
- [ ] 앱: S06 일정 하루(이동 구간 제외), S08 장소 검색, S09 항목 추가·수정(제목 힌트 방식), S10 장소 정보, Google 출처 표시
- [ ] 보안 테스트: 다른 여행의 항목 ID로 수정(S2 규칙), 호출 제한 초과

**위협**: T06·T20·T23·T29 / **로드맵**: 2단계 (시큐어코딩, 외부 API)

### F4. 이동시간·지도 (7주)

- [ ] Google Routes 클라이언트, `GET /days/{date}`에 legs 계산 (구간별 병렬 호출, 실패 구간만 `unavailable`)
- [ ] 좌표 30일 관리 주기 작업 (갱신 또는 삭제)
- [ ] 앱: S06 이동 구간 표시·시각 불일치 경고, S07 지도(마커)
- [ ] 지도 표시용 키를 번들 ID로 제한

**위협**: T20·T23 / **로드맵**: 2단계 (외부 API)

### F5. 초대 링크 (8주)

- [ ] 테이블: invites
- [ ] 생성·목록·폐기, `preview`, `accept` (원자적 사용 횟수 증가)
- [ ] Universal Links(`apple-app-site-association`)·App Links(`assetlinks.json`), W01 안내 웹페이지
- [ ] 앱: S15 초대 링크 관리, S16 초대 참여, 딥링크 처리(로그인 거쳐 돌아오기)
- [ ] 보안 테스트: 토큰 추측 불가, 만료·폐기·소진, 동시 참여로 횟수 우회, 토큰이 로그·쿼리에 남지 않음

**위협**: T10~T14 / **로드맵**: 2단계 (초대 링크)

### F6. 동기화·오프라인 일정 (9주)

- [ ] 앱 로컬 DB(drift): 여행 목록·스냅샷 캐시 (좌표·Google 데이터 제외)
- [ ] "캐시 먼저, 온라인이면 갱신" repository 규칙, 오프라인 배너, 수정 버튼 비활성
- [ ] 409 충돌 대화상자, 403·404 처리, 목록에서 사라진 여행 캐시 삭제
- [ ] 비행기 모드로 전체 흐름 수동 확인

**위협**: T08·T29 / **로드맵**: 2단계 (동시 수정), 3단계 일부

### F7. 바우처 — 서버·온라인 (10주)

- [ ] 바우처 설계 확정 (명세에 포함): 서버 암호화 방식(스토리지 기본 vs 봉투 암호화), 다운로드 방식(서버 경유 vs 짧은 URL)
- [ ] 로컬 S3 호환 저장소 도구 결정 (MinIO 대체), 테이블: vouchers, 비공개 버킷
- [ ] 업로드 (크기 → 시그니처 판별 → 암호화 → 저장), 다운로드 (권한 확인, 응답 헤더), 수정, 삭제
- [ ] 멤버 내보내기·여행 삭제 시 바우처·파일 삭제, 파일 삭제 실패 재시도
- [ ] 앱: S11 바우처 목록, S12 올리기·수정(공개 범위 기본 나만 보기, 공유 경고), S13 보기(온라인)
- [ ] 보안 테스트: 남의 private 바우처 404, 위장 파일, 초과 크기, 버킷 직접 접근 불가

**위협**: T09·T15·T16·T17 / **로드맵**: 3단계 (파일 업로드, 서버 저장)

### F8. 바우처 오프라인 (11주)

- [ ] 기기 암호화 파일 저장소 (AES-GCM, 키는 Keychain/Keystore)
- [ ] 백업 제외 설정 (iOS·Android)
- [ ] "오프라인용으로 모두 받기", 여행 3일 전 안내 배너
- [ ] S13 앱 전환 화면 가림
- [ ] 기기 데이터 정리 규칙 (07-screens 6절): 바우처 삭제·비공개 전환, 여행 제외, 여행 종료 30일 후
- [ ] 릴리스 빌드에서 평문 파일·키가 남지 않는지 직접 확인

**위협**: T18·T19·T21·T31 / **로드맵**: 3단계 (기기 저장)

### F9. 설정·회원 탈퇴 (12주)

- [ ] `DELETE /me` (재인증), 탈퇴 처리 순서 (05-data-model 6절): 바우처 파일, 소유권 이전·여행 삭제, 토큰 폐기
- [ ] 앱: S17 설정, S18 회원 탈퇴, 로그아웃 시 기기 데이터 전체 삭제
- [ ] 보안 테스트: 재인증 없이 탈퇴 불가, 탈퇴 후 토큰 무효, 탈퇴 후 파일 잔존 없음

**위협**: T04·T30 / **로드맵**: 3단계, 6단계 일부 (파기)

### F10. 카카오·Apple 로그인 (11~12주)

- [ ] 카카오: OIDC ID 토큰 검증 추가, 앱 SDK·키 해시 설정
- [ ] Apple: iOS 전용 (Android는 웹 방식이라 도메인·서버 콜백이 추가로 필요해서 제외), 첫 로그인에만 오는 이름 처리, Apple 계정 탈퇴 알림 대응 여부 검토
- [ ] 앱: S02에 카카오·Apple 버튼 추가
- [ ] 보안 테스트: 공급자별 위조·다른 앱용 토큰, 같은 이메일의 다른 공급자 계정이 합쳐지지 않음

**왜 출시 전에 필요한가**: 앱스토어 심사 규칙상 iOS에서 Google 같은 외부 소셜 로그인을 제공하면 Apple 로그인(또는 동등한 개인정보 보호 로그인)도 함께 제공해야 한다. 앱스토어 제출 전까지 반드시 완료
**위협**: T01·T02 / **로드맵**: 1단계

### R. 출시 준비 (12주)

- [ ] 보안 에이전트 전체 점검 → `security/reviews/YYYY-MM-DD-pre-release.md`
- [ ] 위협 모델 "높음" 항목 전부 대응 또는 수용 사유 기록
- [ ] 개인정보 처리방침 초안, 앱스토어 개인정보 라벨·데이터 보안 섹션
- [ ] 스테이징 배포, 실기기 테스트 (TestFlight, Play 내부 테스트)
- [ ] 미해결 결과를 "출시 전 필수 / 출시 후"로 분류

## 4. 위험과 대응

| 위험 | 영향 | 대응 |
|---|---|---|
| 외부 준비물 지연 (Apple 승인 등) | F5·F10 지연 | P3은 F1 전까지, P1·P2는 F5·F10 전까지. Apple 가입은 시간이 걸리니 일찍 시작 |
| Android 확인 지연 (iOS 우선 개발) | Android 전용 문제(SHA-1, 네트워크 설정, App Links, Keystore, 백업 제외)를 늦게 발견 | Android Studio 미설치 상태로 iOS 시뮬레이터에서 먼저 개발. **늦어도 F5(초대 링크·App Links) 전에** Android Studio를 설치해 F1~F4를 Android에서 한 번에 확인 |
| 일정 초과 | 출시 지연 | 순서는 지키고 범위를 줄인다. 줄일 후보: F4 지도 화면, F6 충돌 대화상자의 "다시 적용" |
| Google API 비용 | 예상보다 큰 청구 | P3에서 예산 알림·할당량 상한을 먼저, 개발 중엔 respx 가짜 응답 |
| 스테이징 호스팅 미정 | R 단계에서 실기기 테스트 불가 | F7 전후로 호스팅 결정 (P6) |

## 5. 진행 기록

| 날짜 | 내용 |
|---|---|
| 2026-11-08 | 작업 목록 초안 |
