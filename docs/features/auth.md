# F1. 인증 — Google 로그인

> 상태: 초안 (2026-11-08) — 승인 대기
> 브랜치: `feat/auth`
> 관련 문서: [../05-data-model.md](../05-data-model.md), [../06-api.md](../06-api.md) 3.1·3.2절, [../07-screens.md](../07-screens.md) S01·S02·S17
> 관련 위협: T01, T02, T03, T04, T05, T18, T21, T25
> 로드맵: 1단계 (인증)

## 1. 목적

Google 계정으로 로그인하고, 서버가 발급한 토큰으로 이후 모든 API를 호출할 수 있게 한다. 이 기능은 이후 모든 기능의 "이 요청을 보낸 사람이 누구인가"를 책임진다.

카카오·Apple은 F10에서 붙인다. 이번에 만드는 토큰 발급·갱신·폐기는 공급자와 무관하게 만들어, F10에서는 ID 토큰 검증 부분만 추가한다.

## 2. 사용자 시나리오

**처음 로그인**
1. 앱 첫 화면(S01)에 저장된 토큰이 없음 → 로그인 화면(S02)
2. "Google로 계속하기" → 앱이 서버에 nonce 요청 → Google 로그인 창 → 계정 선택
3. 앱이 Google에서 ID 토큰을 받아 서버에 보냄
4. 서버가 ID 토큰을 검증하고, 처음 보는 Google 계정이면 사용자를 만든 뒤 자체 토큰(액세스·리프레시) 발급
5. 앱이 토큰을 기기 보안 저장소에 저장 → 로그인 후 화면 (F2 전까지는 임시 홈: "○○님 로그인됨" + 로그아웃)

**다시 앱을 열 때**
1. S01에서 저장된 토큰으로 `GET /me` → 성공하면 바로 임시 홈
2. 액세스 토큰이 만료됐으면 앱이 리프레시 토큰으로 자동 갱신 후 재시도
3. 리프레시도 실패하면 기기의 토큰을 지우고 로그인 화면

**로그아웃**
1. 임시 홈의 로그아웃 → 서버에 리프레시 토큰 폐기 요청 → 기기의 토큰 삭제 → 로그인 화면
2. 오프라인이면 기기 토큰은 즉시 지우고, 서버 폐기는 생략 (리프레시 토큰은 30일 뒤 만료)

## 3. 완료 조건

- [ ] iOS 시뮬레이터에서 Google 로그인 → 임시 홈에 내 이름 표시
- [ ] 앱을 껐다 켜면 로그인 상태 유지
- [ ] 액세스 토큰 만료 후에도 사용자 개입 없이 자동 갱신
- [ ] 로그아웃하면 서버의 리프레시 토큰이 폐기되고 기기 토큰이 지워짐
- [ ] 8절 보안 테스트 전부 통과
- [ ] 서버·앱 테스트, lint 통과, 실행 가이드(00) 갱신
- [ ] Android 실행 확인은 범위 밖 (아래 4절)

## 4. 범위 밖

| 항목 | 시점 |
|---|---|
| 카카오·Apple 로그인 | F10 |
| 회원 탈퇴 (`DELETE /me`) | F9 |
| 여러 소셜 계정을 한 사용자에 연결 | MVP 범위 밖 |
| 사용자별 요청 횟수 제한 | F3 (이번엔 IP 기준 `/auth/*`만) |
| Android 실기기·에뮬레이터 확인 | iOS로 개발을 진행한 뒤 확인 (09-tasks 4절). 코드와 설정은 이번에 함께 작성 |
| 정식 홈 화면(여행 목록) | F2 |

## 5. 핵심 설계 결정

### 5.1 Google 클라이언트 구성

| 클라이언트 | 용도 | 코드·설정에 들어가는 곳 |
|---|---|---|
| 웹 (`Travel Copilot Server`) | **ID 토큰의 aud.** 서버의 신분증 | 서버 `GOOGLE_WEB_CLIENT_ID`, 앱의 `serverClientId` |
| iOS | iOS 앱이 로그인 창을 띄울 자격 | 앱 `clientId`(iOS), Info.plist URL scheme |
| Android | 패키지 이름 + SHA-1로 앱 확인 | 코드에 없음 (Google이 서명으로 확인) |

앱은 두 플랫폼 모두 웹 클라이언트 ID를 `serverClientId`로 넘긴다. 그래서 ID 토큰의 aud는 항상 웹 클라이언트 ID이고, 서버는 그것만 받는다.

### 5.2 Google ID 토큰 검증 (서버)

| 검사 | 기준 | 막는 것 |
|---|---|---|
| 서명 | Google 공개키(JWKS)로 **RS256만** 허용. 공개키는 응답의 `Cache-Control` 기간만큼 캐시 | 위조 토큰, 알고리즘 바꿔치기(`none`, HS256 혼동) |
| `iss` | `https://accounts.google.com` 또는 `accounts.google.com` | 다른 발급자 |
| `aud` | `GOOGLE_WEB_CLIENT_ID`와 정확히 같음 | **다른 앱용 Google 토큰** (T01) |
| `azp` | 설정된 경우 우리 iOS·Android 클라이언트 ID 중 하나 | 우리 앱이 아닌 곳에서 받은 토큰 (추가 방어) |
| `exp`, `iat` | 만료 확인, 시계 오차 60초 허용 | 오래된 토큰 |
| `nonce` | 서버가 발급했고, 만료 전이고, **아직 안 쓴** nonce | 가로챈 토큰 재전송 |
| `sub` | 사용자 식별자. `(google, sub)`로 사용자 조회 | — |

- **이메일로 사용자를 찾지 않는다** (T02). 이메일은 `email_verified`가 true일 때만 표시용으로 저장
- 라이브러리: PyJWT (JWT 검증) + httpx (공개키 조회, 비동기). Google의 `google-auth` 라이브러리는 동기 호출이라 쓰지 않는다
- 공개키 조회 실패 시 `502 upstream_error`

### 5.3 nonce

| 항목 | 내용 |
|---|---|
| 발급 | `POST /auth/nonce` → 32바이트 랜덤(`secrets.token_urlsafe`), 5분 유효 |
| 저장 | DB `auth_nonces` 테이블에 **해시만** |
| 사용 | 로그인 시 ID 토큰 안의 `nonce` 값을 해시해서, 만료 전·미사용 행을 **원자적으로 삭제** (`DELETE ... RETURNING`). 없으면 거절 |
| 정리 | 발급할 때 만료된 행을 함께 삭제 |

ID 토큰 안에 nonce가 들어 있으므로, 로그인 요청 본문에는 nonce를 따로 보내지 않는다 (06-api 갱신).

> 확인 필요: `google_sign_in` 7.x의 `initialize(nonce: ...)`가 iOS·Android 모두에서 ID 토큰의 `nonce`에 값을 그대로 넣는지 구현 중 확인한다. 안 되면 이 절을 고쳐서 다시 승인받는다.

### 5.4 자체 토큰

| 항목 | 액세스 토큰 | 리프레시 토큰 |
|---|---|---|
| 형식 | **JWT (HS256)** | 불투명 랜덤 문자열 (32바이트) |
| 유효 시간 | 15분 | 30일, 쓸 때마다 새로 발급(교체) |
| 서버 저장 | 저장 안 함 | `refresh_tokens`에 SHA-256 해시만 |
| 폐기 | 만료로만 (최대 15분) | 즉시 (DB) |

**JWT로 정한 이유**: 요청마다 토큰 테이블을 조회하지 않아도 된다. 대신 로그아웃해도 액세스 토큰이 최대 15분 살아 있다 — 이 차이는 수용한다. 단, 인증 의존성은 요청마다 사용자 행을 읽으므로 **사용자가 삭제되면 즉시 401**이 된다.

**액세스 토큰 내용**: `sub`(사용자 UUID), `iss`(`travel-copilot`), `aud`(`travel-copilot-api`), `iat`, `exp`, `jti`. 이름·이메일 같은 개인정보는 넣지 않는다 (JWT 본문은 누구나 읽을 수 있음).

**검증**: 알고리즘은 HS256만, `iss`·`aud`·`exp` 필수. 서명 키 `JWT_SECRET`은 32바이트 이상, 환경변수로만.

**리프레시 토큰 교체와 재사용 감지** (T03)
1. `UPDATE refresh_tokens SET used_at = now() WHERE token_hash = :h AND used_at IS NULL AND revoked_at IS NULL AND expires_at > now() RETURNING ...`
2. 갱신된 행이 있으면 → 같은 `family_id`로 새 리프레시 토큰 + 새 액세스 토큰 발급
3. 없는데 해시가 존재하고 이미 사용됨 → **탈취로 판단**: 그 `family_id` 전체 폐기, `401 token_invalid`, 경고 로그
4. 아예 없음 → `401 token_invalid`

앱이 동시에 갱신 요청을 두 번 보내면 3번에 걸려 로그아웃될 수 있다. 그래서 **앱은 갱신을 한 번에 하나만** 보낸다 (동시 요청은 첫 갱신 결과를 기다림).

### 5.5 요청 횟수 제한

- `/auth/*`에 IP 기준 분당 10회 (06-api 5절)
- 서버 1대 기준 메모리 카운터 (`core/rate_limit.py`). IP는 Nginx가 넣은 `X-Forwarded-For` (F0에서 Nginx만 믿도록 설정됨)
- 초과 시 `429 rate_limited` + `Retry-After`

## 6. API

| 메서드 | 경로 | 권한 | 변경 |
|---|---|---|---|
| POST | `/api/v1/auth/nonce` | 🌐 | 신규 |
| POST | `/api/v1/auth/google/login` | 🌐 | 신규 (06-api의 `/auth/{provider}/login` 중 google) |
| POST | `/api/v1/auth/refresh` | 🌐 | 신규 |
| POST | `/api/v1/auth/logout` | 👤 | 신규 |
| GET | `/api/v1/me` | 👤 | 신규 |
| PATCH | `/api/v1/me` | 👤 | 신규 (표시 이름) |

```json
// POST /auth/nonce → 200
{ "nonce": "Vt3x...", "expires_in": 300 }

// POST /auth/google/login
{ "id_token": "eyJ...", "display_name": "홍길동" }   // display_name은 선택, 처음 가입할 때만 사용
// → 200
{
  "access_token": "eyJ...", "token_type": "Bearer", "expires_in": 900,
  "refresh_token": "q9K...",
  "user": { "id": "0193...", "display_name": "홍길동" },
  "is_new_user": true
}

// POST /auth/refresh
{ "refresh_token": "q9K..." }   // → 200, 로그인 응답과 같은 형식 (is_new_user 제외)

// POST /auth/logout  (Authorization 헤더 필요)
{ "refresh_token": "q9K..." }   // → 204. 본인 토큰 묶음만 폐기, 이미 폐기됐어도 204

// GET /me → 200
{ "id": "0193...", "display_name": "홍길동", "email": "user@gmail.com" }

// PATCH /me
{ "display_name": "길동" }   // → 200, GET /me와 같은 형식
```

| 에러 | 상황 |
|---|---|
| `401 token_missing` | Authorization 헤더 없음 |
| `401 token_expired` | 액세스 토큰 만료 → 앱이 갱신 |
| `401 token_invalid` | 서명·형식·aud·iss 오류, 폐기된 리프레시 토큰, 삭제된 사용자 |
| `401 id_token_invalid` | Google ID 토큰 검증 실패 (어떤 검사에서 실패했는지는 응답에 넣지 않고 서버 로그에만) |
| `401 nonce_invalid` | nonce 없음·만료·이미 사용 |
| `422 validation_error` | 입력값 오류, 정의되지 않은 필드 |
| `429 rate_limited` | 요청 횟수 초과 |
| `502 upstream_error` | Google 공개키 조회 실패 |

- 표시 이름: 1~50자, 앞뒤 공백 제거. 처음 가입 시 `display_name`이 없으면 Google `name`, 그것도 없으면 "여행자"

## 7. 데이터 변경

05-data-model의 `users`, `social_accounts`, `refresh_tokens`를 그대로 만들고, `auth_nonces`를 추가한다.

| 테이블 | 비고 |
|---|---|
| `users` | id, display_name, email(NULL), created_at, updated_at |
| `social_accounts` | provider enum은 처음부터 `kakao`·`apple`·`google` 3개. UNIQUE(provider, subject) |
| `refresh_tokens` | id, user_id, family_id, token_hash(UNIQUE), expires_at, used_at, revoked_at, created_at. 인덱스: family_id |
| **`auth_nonces` (신규)** | nonce_hash(PK, char 64), expires_at, created_at |

- 마이그레이션 1개: `create_auth_tables`
- 만료된 `refresh_tokens` 정리 작업은 F4의 주기 작업과 함께 (그 전까지는 쌓이기만 함, 용량 문제 없음)

## 8. 보안 요구사항

| 위협 | 요구사항 | 확인 방법 (테스트) |
|---|---|---|
| T01 | 다른 키로 서명한 ID 토큰 거절 | `test_google_login_with_forged_signature_returns_401` |
| T01 | aud가 다른 앱인 ID 토큰 거절 | `test_google_login_with_other_audience_returns_401` |
| T01 | iss가 다른 토큰 거절 | `test_google_login_with_wrong_issuer_returns_401` |
| T01 | 만료된 ID 토큰 거절 | `test_google_login_with_expired_token_returns_401` |
| T01 | `alg: none`, HS256(공개키를 비밀키로 쓴 위조) 거절 | `test_google_login_with_alg_confusion_returns_401` |
| T01 | azp가 우리 앱이 아니면 거절 (설정 시) | `test_google_login_with_unknown_azp_returns_401` |
| T01 | nonce 없음·모름·만료·재사용 거절 | `test_google_login_nonce_*` 4종 |
| T02 | 이메일이 같아도 sub가 다르면 다른 사용자 | `test_same_email_different_sub_creates_separate_users` |
| T03 | 쓴 리프레시 토큰 재사용 시 묶음 전체 폐기 | `test_refresh_token_reuse_revokes_family` |
| T03 | 리프레시 토큰은 DB에 해시로만 | `test_refresh_token_stored_as_hash` |
| T04 | 로그아웃 후 리프레시 토큰 거절 | `test_refresh_after_logout_returns_401` |
| T04 | 삭제된 사용자의 액세스 토큰 거절 | `test_access_token_of_deleted_user_returns_401` |
| T01 | 액세스 토큰: 위조·만료·aud/iss 오류·`alg: none` 거절 | `test_access_token_*` |
| T05 | `/auth/*` 분당 10회 초과 시 429 | `test_auth_rate_limit_returns_429` |
| T25 | ID 토큰·액세스·리프레시 토큰·nonce가 로그에 남지 않음 | `test_auth_logs_exclude_tokens` |
| T18 | 앱: 토큰은 secure storage에만, iOS는 이 기기 전용(iCloud 키체인 동기화 안 함) | 코드 리뷰 + 저장소 단위 테스트 |
| T21 | 앱: 토큰을 로그에 출력하지 않음 | 코드 리뷰 |

Google 공개키는 테스트 안에서 RSA 키 쌍을 만들어 respx로 가짜 JWKS를 응답한다 (실제 Google 호출 없음).

## 9. 앱

| 항목 | 내용 |
|---|---|
| 패키지 | `google_sign_in`, `flutter_secure_storage` |
| 설정 | `env/*.json`에 `GOOGLE_SERVER_CLIENT_ID`(웹), `GOOGLE_IOS_CLIENT_ID` 추가 (공개값). iOS Info.plist에 iOS 클라이언트의 reversed client ID URL scheme |
| 토큰 저장 (`core/storage/token_storage.dart`) | flutter_secure_storage. iOS 접근성 `first_unlock_this_device` (기기 백업·다른 기기로 이전 안 됨), Android 기본(Keystore) |
| 인증 상태 (`features/auth/state`) | 로그인됨 / 안 됨을 앱 전체가 구독. 라우터가 이 상태로 로그인 화면·홈을 전환 |
| API 클라이언트 (`core/api`) | 요청에 액세스 토큰 첨부. `401 token_expired`면 **한 번에 하나만** 갱신 후 원래 요청 1회 재시도. 갱신 실패 시 토큰 삭제 → 로그인 화면 |
| 화면 | S01 시작(토큰 확인), S02 로그인(Google 버튼만), 임시 홈(이름 + 로그아웃). F0의 서버 상태 화면은 삭제 |
| 로그인 실패 메시지 | 일반 문구만 ("로그인하지 못했습니다. 다시 시도해주세요"). 사용자가 Google 창을 닫은 경우는 메시지 없음 |

## 10. 테스트 계획

- **서버 단위**: Google 검증기(정상·각 검사 실패), JWT 발급·검증, nonce 저장·소비, 리프레시 교체 로직, 요청 횟수 제한
- **서버 API** (필수 5종 포함): 6절의 모든 엔드포인트 — 토큰 없음 401, 정의되지 않은 필드 422, 정상 응답 형식. (비멤버 404·역할 403은 여행 기능부터 해당)
- **보안**: 8절 테스트 전부 (`tests/security/test_auth_*.py`)
- **앱**: 토큰 저장소, 갱신 인터셉터(동시 401 → 갱신 1번), 인증 상태 전환, 로그인 화면 위젯
- **수동 확인 (iOS 시뮬레이터)**
  1. 로그인 → 임시 홈에 이름
  2. 앱 재시작 → 로그인 유지
  3. 서버 `ACCESS_TOKEN_TTL`을 짧게 해서 자동 갱신 확인
  4. 로그아웃 → DB에서 리프레시 토큰 `revoked_at` 확인
  5. 같은 리프레시 토큰을 curl로 두 번 보내기 → 두 번째에 묶음 전체 폐기

## 11. 서버 설정 추가

| 환경변수 | 설명 |
|---|---|
| `JWT_SECRET` | 액세스 토큰 서명 키 (32바이트 이상 무작위). `.env`에만 |
| `GOOGLE_WEB_CLIENT_ID` | 웹 클라이언트 ID (ID 토큰 aud) |
| `GOOGLE_ALLOWED_AZP` | 쉼표로 구분한 iOS·Android 클라이언트 ID (선택, 있으면 azp 검사) |
| `ACCESS_TOKEN_TTL_SECONDS` | 기본 900 (수동 테스트 때만 줄임) |

## 12. 열린 질문

- `JWT_SECRET` 교체 방법 (토큰 헤더의 `kid`로 여러 키 지원) — 운영 배포(로드맵 5단계)에서
- Google 공개키 조회가 계속 실패할 때 대응 — 캐시된 키로 계속 검증할지 (현재: 캐시 만료 전까지는 캐시 사용, 만료 후 조회 실패 시 502)
