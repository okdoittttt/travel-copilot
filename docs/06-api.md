# API 명세

> 상태: 초안 (2026-11-08) — 승인 대기
> 범위: MVP (M1 일정·동선, M4 협업·오프라인 바우처 지갑, 소셜 로그인)
> 관련 문서: [04-architecture.md](04-architecture.md), [05-data-model.md](05-data-model.md), [../security/threat-model.md](../security/threat-model.md)
> 상세 요청·응답 필드는 기능 명세(`docs/features/`)와 서버가 생성하는 OpenAPI 문서에서 확정한다. 이 문서는 엔드포인트 목록, 권한, 공통 규칙을 정한다

## 1. 공통 규칙

| 항목 | 규칙 |
|---|---|
| 기본 경로 | `https://<도메인>/api/v1` |
| 형식 | 요청·응답 JSON (`application/json`). 바우처 업로드만 `multipart/form-data` |
| 인증 | `Authorization: Bearer <access_token>`. 표시가 없는 API는 모두 인증 필요 |
| 필드 이름 | `snake_case` |
| 시간 | 시각은 UTC ISO 8601 (`2026-11-08T03:00:00Z`), 현지 날짜는 `YYYY-MM-DD`, 현지 시각은 `HH:MM` |
| 동시 수정 | 수정·삭제 요청에 `version` 필수. 서버 값과 다르면 `409` + 현재 데이터 |
| 목록 | 커서 방식: `?cursor=...&limit=20` → 응답에 `next_cursor` (없으면 `null`) |
| 캐시 | 모든 응답에 `Cache-Control: no-store` (개인정보, Google 데이터 캐시 제한) |
| 알 수 없는 필드 | 요청에 정의되지 않은 필드가 있으면 `422` (Pydantic `extra="forbid"`) — 권한 필드 몰래 넣기 방지 |

## 2. 에러 형식

RFC 9457 (`application/problem+json`) + 앱이 분기할 때 쓰는 `code`:

```json
{
  "type": "about:blank",
  "title": "Version conflict",
  "status": 409,
  "code": "version_conflict",
  "detail": "다른 멤버가 먼저 수정했습니다.",
  "current": { "...": "최신 데이터 (409일 때만)" }
}
```

| 상태 | 의미 | 대표 `code` |
|---|---|---|
| 400 | 요청 의미 오류 | `invalid_request` |
| 401 | 인증 없음·만료 | `token_missing`, `token_expired`, `token_invalid` |
| 403 | 멤버지만 권한 부족 | `forbidden` |
| 404 | 없음 **또는 비멤버** (여행 존재 여부도 숨김) | `not_found` |
| 409 | 동시 수정 충돌, 상태 충돌 | `version_conflict`, `already_member`, `owner_cannot_leave` |
| 410 | 초대 링크 만료·폐기·횟수 소진 | `invite_expired`, `invite_revoked`, `invite_exhausted` |
| 413 | 파일·요청 크기 초과 | `payload_too_large` |
| 415 | 허용하지 않는 파일 형식 | `unsupported_file_type` |
| 422 | 입력값 검증 실패 | `validation_error` (+ `errors` 배열: 필드, 이유) |
| 429 | 요청 횟수 초과 | `rate_limited` (+ `Retry-After` 헤더) |
| 502 | Google 등 외부 API 실패 | `upstream_error` |
| 500 | 서버 오류 | `internal_error` (내부 정보·스택 트레이스 없음) |

**401 vs 403 vs 404 규칙**
- 토큰이 없거나 틀림 → 401
- 비멤버가 여행 리소스 접근 → **404** (403이 아님)
- 멤버인데 역할 부족 (예: viewer가 일정 수정) → 403
- 남의 `private` 바우처 → **404**

## 3. 엔드포인트 목록

권한 표기: 🌐 인증 불필요 / 👤 로그인 사용자 / O owner / E editor / V viewer / 본인 = 자기 리소스만

### 3.1 인증

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| POST | `/auth/nonce` | 🌐 | 로그인용 nonce 발급 (5분, 1회용, DB에 해시 저장 — features/auth.md 5.3) |
| POST | `/auth/{provider}/login` | 🌐 | `provider` = `kakao` \| `apple` \| `google`. ID 토큰(안에 nonce 포함) → 토큰 발급. 처음이면 가입 |
| POST | `/auth/refresh` | 🌐 | 리프레시 토큰 → 새 액세스·리프레시 토큰 (리프레시 토큰은 매번 교체) |
| POST | `/auth/logout` | 👤 | 현재 리프레시 토큰 묶음 폐기 |

```json
// POST /auth/apple/login
{ "id_token": "eyJ...", "display_name": "홍길동" }   // nonce는 ID 토큰 안에 들어 있어 따로 보내지 않음 (features/auth.md 5.3)

// 200
{
  "access_token": "...", "expires_in": 900,
  "refresh_token": "...",
  "user": { "id": "0193...", "display_name": "홍길동" },
  "is_new_user": true
}
```

- `display_name`은 처음 가입할 때만 쓰인다 (Apple은 첫 로그인에만 이름을 준다)
- 이메일로 기존 계정과 자동 연결하지 않는다 (T02)

### 3.2 내 정보

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| GET | `/me` | 👤 | 내 정보 |
| PATCH | `/me` | 👤 | 표시 이름 변경 |
| DELETE | `/me` | 👤 | 회원 탈퇴. **재인증 필요**: 요청 본문에 방금 받은 ID 토큰 + nonce. 처리 순서는 05-data-model.md 6절 |

### 3.3 여행

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| GET | `/trips` | 👤 | 내가 멤버인 여행 목록 (커서). 앱은 여기 없는 여행의 캐시를 지운다 |
| POST | `/trips` | 👤 | 여행 만들기. 만든 사람이 owner |
| GET | `/trips/{trip_id}` | O E V | **여행 스냅샷**: 여행 정보 + 내 역할 + 멤버 + 전체 일정 항목 + 내가 볼 수 있는 바우처 목록. 새로고침·오프라인 캐시용 |
| PATCH | `/trips/{trip_id}` | O E | 제목·목적지·기간·시간대 수정 (`version` 필수). 기간을 줄여 밖으로 밀려나는 일정 항목이 있으면 `409` |
| DELETE | `/trips/{trip_id}?version=N` | O | 여행 삭제 (바우처 파일 포함). `version`은 본문 대신 쿼리로 |

**스냅샷 응답의 Google 데이터**
- 일정 항목에는 `place_id`, 좌표, 사용자가 쓴 제목·메모만 들어간다. 장소 이름·주소·이동시간은 없다
- 앱 로컬 DB에는 **좌표를 저장하지 않는다** (서버는 30일 관리가 가능하지만 기기 캐시는 관리가 어려움). 좌표는 메모리에서만 지도 표시에 쓴다

### 3.4 멤버

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| PATCH | `/trips/{trip_id}/members/{user_id}` | O | 역할 변경 (`editor` ↔ `viewer`) |
| DELETE | `/trips/{trip_id}/members/{user_id}` | O, 또는 본인 | owner가 내보내기 / 본인이 나가기. owner는 나갈 수 없음 (`409 owner_cannot_leave`). 해당 멤버의 바우처 삭제 |
| POST | `/trips/{trip_id}/transfer-ownership` | O | `{ "user_id": "..." }` 멤버에게 owner 넘기기. 기존 owner는 editor가 됨 |

### 3.5 일정

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| GET | `/trips/{trip_id}/days/{date}` | O E V | 하루 일정 + **이동 구간(legs)**. 이동시간은 이 요청 때 Google Routes로 계산하고 저장하지 않는다 |
| POST | `/trips/{trip_id}/items` | O E | 일정 항목 추가 (`day`, `title`, 선택: `place_id`, `memo`, `start_time`, `stay_minutes`, `travel_mode`, `position`) |
| PATCH | `/trips/{trip_id}/items/{item_id}` | O E | 항목 수정 (`version` 필수). `day`를 바꾸면 다른 날로 이동 (맨 뒤에 붙음) |
| DELETE | `/trips/{trip_id}/items/{item_id}?version=N` | O E | 항목 삭제. 연결된 바우처는 남음 |
| PUT | `/trips/{trip_id}/days/{date}/order` | O E | 하루 순서 변경. `{ "items": [{ "id", "version" }, ...] }` — 그날의 모든 항목이 정확히 들어 있어야 함 |

```json
// GET /trips/{trip_id}/days/2026-12-24 → 200
{
  "date": "2026-12-24",
  "items": [
    { "id": "...", "position": 0, "title": "숙소", "place_id": "ChIJ...",
      "location": { "lat": 48.8566, "lng": 2.3522 },
      "start_time": "09:00", "stay_minutes": null, "travel_mode": null, "memo": null, "version": 3 },
    { "id": "...", "position": 1, "title": "오르세 미술관", "place_id": "ChIJ...",
      "location": { "lat": 48.8600, "lng": 2.3266 },
      "start_time": "10:00", "stay_minutes": 180, "travel_mode": "transit", "memo": "목요일 야간 개장", "version": 1 }
  ],
  "legs": [
    { "from_item_id": "...", "to_item_id": "...", "mode": "transit",
      "status": "ok", "duration_seconds": 1260, "distance_meters": 3900 }
  ]
}
```

- `legs[].status`: `ok` / `no_location`(장소 없는 항목) / `no_mode`(이동수단 미선택) / `unavailable`(Google이 경로를 못 찾음, 외부 오류)
- 이동시간 계산이 실패해도 일정 자체는 `200`으로 돌려준다 (해당 구간만 `unavailable`)
- 앱은 `legs`를 **로컬에 저장하지 않는다** (Google 약관)
- "동선이 꼬였을 때 경고"는 2차

### 3.6 장소 검색 (Google 대리 호출)

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| GET | `/places/autocomplete?q=&session_token=&lat=&lng=` | 👤 | 자동완성. `lat`·`lng`은 결과 위치 편향용(선택). `session_token`은 Google 과금 세션용으로 앱이 생성 |
| GET | `/places/{place_id}?session_token=` | 👤 | 장소 상세: 이름, 주소, 좌표, Google 지도 링크, **출처 표시(attribution) 정보** |

- Google API 키는 서버에만 있다 (T20). 필드 마스크로 필요한 항목만 요청한다 (비용·약관)
- 응답은 화면에 보여주는 용도이고, 앱은 이름·주소를 저장하지 않는다
- 화면에는 Google 출처 표시를 반드시 같이 보여준다 (약관)

### 3.7 초대

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| POST | `/trips/{trip_id}/invites` | O | 링크 만들기 `{ "role", "max_uses", "expires_in_days" }` → `{ "id", "url", "expires_at" }`. **토큰 원문은 이 응답에서 한 번만** 나온다 |
| GET | `/trips/{trip_id}/invites` | O | 링크 목록 (토큰 없음: 역할, 사용 횟수, 만료, 폐기 여부) |
| DELETE | `/trips/{trip_id}/invites/{invite_id}` | O | 링크 폐기 |
| POST | `/invites/preview` | 👤 | `{ "token" }` → 참여 확인 화면용 정보: 여행 제목, 초대한 사람 이름, 받을 역할, 기간. 그 외 정보 없음 |
| POST | `/invites/accept` | 👤 | `{ "token" }` → 멤버로 추가, `{ "trip_id" }`. 이미 멤버면 `409 already_member` |

**초대 링크 형식**: `https://<도메인>/invite#<token>`
- 토큰을 URL 경로·쿼리가 아니라 **`#` 뒤(fragment)**에 넣는다. fragment는 브라우저가 서버로 보내지 않아서, 웹 서버 로그나 리퍼러에 토큰이 남지 않는다
- 앱은 Universal Link / App Link로 열리며 전체 URL(fragment 포함)을 받는다 (T13)
- 토큰은 요청 본문으로만 서버에 보낸다 (쿼리 문자열 금지 — 로그에 남음)
- 존재하지 않는 토큰은 `404`, 만료·폐기·소진은 `410`

### 3.8 바우처

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| POST | `/trips/{trip_id}/vouchers` | O E V | 업로드 (multipart: `file`, `title`, `visibility`, 선택: `day`, `itinerary_item_id`) |
| GET | `/trips/{trip_id}/vouchers/{voucher_id}/file` | 본인, 또는 `trip` 공개면 멤버 | 파일 다운로드 |
| PATCH | `/trips/{trip_id}/vouchers/{voucher_id}` | 본인 | 제목·공개 범위·날짜·연결 항목 수정 (`version` 필수) |
| DELETE | `/trips/{trip_id}/vouchers/{voucher_id}?version=N` | 본인 | 삭제 (파일 포함) |

- 바우처 목록은 여행 스냅샷(`GET /trips/{trip_id}`)에 들어 있다
- **업로드 검증** (T15): 크기 먼저 확인(Nginx + 서버), 파일 시그니처로 형식 판별, 클라이언트가 보낸 `Content-Type`·파일 이름은 믿지 않음
- **다운로드 응답 헤더**: `Content-Type`(서버가 판별한 값), `Content-Disposition: attachment`, `X-Content-Type-Options: nosniff`, `Cache-Control: no-store`
- 다운로드 방식(서버 경유 vs 짧게 만료되는 직접 URL)은 바우처 설계에서 확정. 어느 쪽이든 이 경로로 요청하고, 권한 확인은 서버가 한다

### 3.9 기타

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| GET | `/health` | 🌐 | 서버 상태. 버전·내부 정보는 노출하지 않음 |

## 4. 제한값

| 항목 | 값 |
|---|---|
| 여행 기간 | 최대 60일 |
| 제목류 (여행·일정·바우처) | 1~100자 |
| 메모 | 최대 1,000자 |
| 표시 이름 | 1~50자 |
| 여행당 멤버 | 최대 20명 |
| 하루 일정 항목 | 최대 50개 |
| 초대 링크 사용 횟수 | 1~20회, 기본 10회 |
| 초대 링크 유효 기간 | 1~7일, 기본 3일 |
| 여행당 열린 초대 링크 | 최대 5개 |
| 바우처 파일 | 최대 10MB, PDF·JPEG·PNG |
| 바우처 개수 | 여행당 사용자 1명이 최대 50개 |
| 액세스 토큰 유효 시간 | 15분 |
| 리프레시 토큰 유효 시간 | 30일 (쓸 때마다 교체) |

## 5. 요청 횟수 제한

| 대상 | 기준 | 제한 |
|---|---|---|
| `/auth/*` | IP | 분당 10회 |
| `/places/autocomplete` | 사용자 | 분당 60회, 하루 1,000회 |
| `/places/{place_id}` | 사용자 | 하루 300회 |
| `GET /trips/{id}/days/{date}` (Routes 호출) | 사용자 | 시간당 120회 |
| `/invites/preview`, `/invites/accept` | 사용자 | 분당 10회 |
| 바우처 업로드 | 사용자 | 시간당 30회 |
| 그 외 | 사용자 | 분당 120회 |

- Google Cloud 쪽에도 일일 할당량 상한과 예산 알림을 따로 건다 (T23)
- 수치는 출시 후 실제 사용량을 보고 조정한다

## 6. 위협 대응 매핑

| 위협 | API에서의 대응 |
|---|---|
| T01·T02 | `/auth/{provider}/login`에서 ID 토큰 전체 검증, `(provider, sub)`로 식별 |
| T03·T04 | `/auth/refresh` 토큰 교체·재사용 감지, `/auth/logout`·`DELETE /me` 폐기 |
| T06·T07·T08 | 모든 `/trips/{trip_id}/...`에 멤버·역할 확인, 비멤버는 404 |
| T09 | `private` 바우처는 본인 외 404 |
| T10~T14 | 초대 토큰 fragment 전달, 본문으로만 제출, 만료·횟수·폐기, 원자적 사용 횟수 증가 |
| T15·T16 | 업로드 검증, 다운로드 헤더, 권한 확인 후에만 파일 제공 |
| T20·T23 | Google 키 서버 보관, 사용자별 호출 제한 |
| T26·T27 | 에러 형식 통일, 내부 정보 미노출, 알 수 없는 필드 거절 |

## 7. 열린 질문

- 액세스 토큰을 JWT로 할지 불투명 토큰(DB 조회)으로 할지 → 인증 설계(1단계)에서 결정. API 형태는 같다
- 이동시간 계산 비용: 하루 항목 N개면 Routes 호출 N-1번. 같은 날을 자주 다시 열면 비용이 늘어난다. 실제 사용량을 보고 조정한다 (약관상 결과 캐시가 어려움)
