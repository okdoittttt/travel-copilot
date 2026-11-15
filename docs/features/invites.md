# F5. 초대 링크

> 상태: 구현 완료 (2026-11-15) — 수동 확인 대기 (00 가이드 42~49번)
> 브랜치: `feat/trips` (작업 브랜치 하나를 계속 사용)
> 관련 문서: [../05-data-model.md](../05-data-model.md) 4절 invites·5절 권한표, [../06-api.md](../06-api.md) 3.7·4·5절, [../07-screens.md](../07-screens.md) S14·S15·S16·W01, [trips.md](trips.md)
> 관련 위협: T10, T11, T12, T13, T14 (+ 새로 T33)
> 로드맵: 2단계 (초대 링크)

## 1. 목적

owner가 **초대 링크**를 만들어 단톡방 등으로 보내면, 받은 사람이 로그인한 뒤 정해진 역할(편집자·보기 전용)로 여행에 참여한다. F2에서 "멤버를 추가하는 방법"만 비워 두었는데, 그 자리를 채운다.

링크는 누가 받아 갈지 모르는 채널(B5)로 퍼진다. 그래서 핵심은 **링크가 새도 피해가 작게**(만료·횟수·폐기·기본 보기 전용) 하고, **토큰이 남는 곳이 없게**(해시 저장, fragment, 본문 전송, 로그 금지) 하는 것이다.

## 2. 사용자 시나리오

**링크 만들기 (owner)**
1. 멤버 화면(S14) → [초대 링크] → S15
2. [새 링크] → 역할(기본 **보기 전용**), 사용 횟수(기본 10), 유효 기간(기본 3일) → [만들기]
3. 편집자를 고르면 경고: "링크를 받은 누구나 일정을 수정할 수 있습니다"
4. 만들자마자 OS 공유 시트가 열린다. 링크 주소는 **이때만** 볼 수 있다 (다시 보기 불가, 필요하면 새로 만들기)
5. 목록에서 역할·사용 횟수(3/10)·남은 기간·상태를 보고, [폐기]로 바로 막을 수 있다

**참여 (받은 사람)**
1. 단톡방에서 링크를 누른다 → 앱이 열린다 (Universal Link / App Link)
   - 링크로 앱이 안 열리는 환경(도메인 준비 전, 앱 미설치 후 설치 등): 여행 목록(S03) 메뉴 [초대 링크로 참여] → 링크 붙여넣기
2. 로그인이 안 돼 있으면 로그인 → 끝나면 참여 화면으로 돌아온다
3. "홍길동 님이 '파리 여행'(12/22~12/29)에 보기 전용 멤버로 초대했습니다" [참여] [취소]
4. [참여] → 여행 상세(S05)
5. 이미 멤버면 확인 없이 바로 S05. 만료·폐기·소진이면 "더 이상 쓸 수 없는 초대 링크입니다. 초대한 사람에게 새 링크를 요청하세요"

**앱이 없는 사람**: 링크가 브라우저에서 열리고 안내 웹페이지(W01)가 보인다. 앱 설치 후 링크를 다시 열어달라고 안내한다.

## 3. 완료 조건

- [ ] owner가 링크를 만들고·목록을 보고·폐기할 수 있다. editor·viewer는 403, 비멤버는 404
- [ ] 다른 계정이 링크(붙여넣기 경로)로 미리보기 → 참여 → 여행 목록에 그 여행이 보인다
- [ ] 만료·폐기·소진 링크는 410, 이미 멤버는 409이며 사용 횟수가 늘지 않는다
- [ ] 8절 보안 테스트 전부 통과 + 방어 제거 시험
- [ ] Universal Links·App Links 설정 파일과 W01이 준비돼 있고, 도메인·Apple 계정 없이도 빌드·테스트가 된다 (실제 링크 열기 확인은 10절 준비물이 생긴 뒤)
- [ ] 서버·앱 테스트, lint 통과, 실행 가이드(00) 갱신

## 4. 범위 밖

| 항목 | 이유·시점 |
|---|---|
| 카카오톡 공유 API (메시지 카드) | 카카오 앱 등록(P2)이 F10에서. 지금은 OS 공유 시트로 카카오톡도 보낼 수 있음 |
| 특정 사람만 쓸 수 있는 초대 (이메일·사용자 지정) | MVP는 링크 방식. 필요하면 2차 |
| 참여 승인제 (owner가 수락해야 참여) | 단계가 늘어남. 링크 유출 대응은 만료·횟수·폐기·내보내기로 (T11) |
| 링크로 owner 권한 부여 | 불가 (owner는 소유권 넘기기로만, F2) |
| 링크를 다시 보여주기 | 토큰 원문을 저장하지 않으므로 불가 (T14). 새로 만들기 |
| 운영 도메인에서 실제 링크 열기 검증 | 10절 P1·P4가 준비되면 (11절 열린 질문 1) |
| 오프라인 상태 참여 | 서버 확인이 필요한 동작 |

## 5. 핵심 설계 결정

### 5.1 토큰 — 256비트 랜덤, 해시만 저장 (T10·T14)

- 생성: `secrets.token_urlsafe(32)` → 43자 (256비트). 요구사항(128비트 이상)보다 넉넉하게
- 저장: `SHA-256(토큰)`의 16진수 64자만 `token_hash`에. 원문은 **생성 응답에서 한 번만** 내보내고 어디에도 남기지 않는다
- 조회: 받은 토큰을 해시해서 `token_hash`로 찾는다. 해시 비교라 타이밍 공격으로 원문을 알아낼 길이 없다
- 비밀번호처럼 느린 해시(bcrypt)를 쓰지 않는 이유: 토큰 자체가 256비트 랜덤이라 대입이 불가능하고, 빠른 해시여야 UNIQUE 인덱스로 바로 찾을 수 있다
- 형식이 틀린 토큰(43자 `[A-Za-z0-9_-]`가 아님)도 존재하지 않는 토큰과 똑같이 `404`

### 5.2 링크 형식 — 토큰은 `#` 뒤에, 서버에는 본문으로만 (T11)

- 링크: `{INVITE_BASE_URL}/invite#<토큰>` (예: `https://travel.example.com/invite#3fK...`)
- `#` 뒤(fragment)는 브라우저가 서버로 보내지 않는다 → W01을 여는 웹 서버 로그·리퍼러에 토큰이 남지 않는다
- 앱 → 서버는 **요청 본문**으로만: `POST /invites/preview {"token": ...}`. 쿼리 문자열로 보내면 거절(422)
- 서버 로그는 이미 경로만 남기고 본문은 남기지 않는다 (F0). 이번에 테스트로 못 박는다
- `INVITE_BASE_URL`은 설정값. 로컬 기본값 `https://localhost`

### 5.3 참여 — 한 트랜잭션, 원자적 사용 횟수 증가 (T12)

`POST /invites/accept` 처리 순서:
1. 토큰 해시로 초대를 찾는다. 없으면 404
2. 그 여행 행을 `FOR UPDATE`로 잠근다 (F2의 잠금 규칙과 같은 순서: 여행 → 멤버십)
3. 이미 멤버면 `409 already_member` — **사용 횟수를 쓰지 않는다**
4. 멤버 수가 20명이면 `409 trip_member_limit` (F2에서 미룬 상한을 여기서 적용)
5. 조건부 증가: `UPDATE invites SET use_count = use_count + 1 WHERE id = :id AND revoked_at IS NULL AND expires_at > now() AND use_count < max_uses RETURNING ...`
   - 0행이면 이유를 골라 410: 폐기 → `invite_revoked`, 만료 → `invite_expired`, 소진 → `invite_exhausted` (여러 개면 이 순서)
6. 멤버십을 초대의 역할로 추가 → `{ "trip_id" }`

- 여행 행 잠금 + 조건부 UPDATE 이중 방어. 같은 링크로 동시에 여러 명이 눌러도 `max_uses`를 넘지 않고, 같은 사람이 두 번 눌러도 멤버십·사용 횟수는 하나씩
- 미리보기(`preview`)는 사용 횟수를 쓰지 않는다

### 5.4 미리보기가 보여주는 정보 (T33)

링크만 있으면 로그인한 누구나 미리보기를 볼 수 있다. 참여 결정에 필요한 최소 정보만 준다.

| 필드 | 이유 |
|---|---|
| 여행 제목, 시작·종료일 | 어떤 여행인지 |
| 초대한 사람 표시 이름 | 아는 사람인지 확인 (만든 사람이 탈퇴했으면 `null`) |
| 받을 역할 | 편집자인지 보기 전용인지 |
| `already_member`, (멤버일 때만) `trip_id` | 이미 멤버면 바로 이동 |

주지 않는 것: 국가·시간대, 멤버 목록, 일정, 남은 사용 횟수·만료 시각. 링크를 주운 사람(A5)이 참여하지 않고도 알 수 있는 것을 줄인다. 그래도 **제목과 날짜(집이 비는 기간)는 링크만으로 보인다** → 새 위협 T33으로 기록하고, 링크 공유 시 주의를 S15에 안내한다.

### 5.5 링크 관리 규칙

| 규칙 | 값 |
|---|---|
| 만들기·목록·폐기 | owner만 (05-data-model 5절, T11) |
| 역할 | `editor`·`viewer`, 기본 `viewer` |
| 사용 횟수 | 1~20, 기본 10 |
| 유효 기간 | 1~7일, 기본 3일 |
| 여행당 열린 링크 | 최대 5개 (`409 invite_limit`). "열린" = 폐기·만료·소진되지 않은 것 |
| 폐기 | `revoked_at` 기록 (행은 남김). 이미 끝난 링크를 다시 폐기해도 204 |
| 목록 | **만료된 지 30일이 안 된** 링크(열린 링크 포함), 최신순. 토큰은 없음 |
| 정리 | **만료된 지 30일** 지난 초대 행은 F4의 6시간 주기 정리 작업에서 삭제. 폐기·소진된 링크도 7일 안에 만료되므로 함께 지워진다 (소진 시각은 따로 기록하지 않아서 만료 시각을 기준으로 삼음) |
| 여행 삭제 | 초대도 함께 삭제 (FK CASCADE) |
| 소유권 넘기기 | 기존 링크는 유지. 새 owner 목록에 그대로 보이고, 새 owner가 폐기할 수 있다 |

### 5.6 내보낸 멤버가 남은 링크로 다시 들어오는 문제 (T11·A4)

멤버를 내보내도, 그 사람이 받았던 링크가 아직 열려 있으면 다시 참여할 수 있다. 대응:
- **"모든 링크 폐기"** API를 둔다: `POST /trips/{id}/invites/revoke-all`
- S14에서 멤버를 내보낼 때, 열린 링크가 있으면 확인 대화상자에 **"열린 초대 링크도 모두 폐기" 체크박스(기본 선택)**를 보여준다
- 서버가 "내보낸 사람 목록"을 따로 기록해 막는 방식은 쓰지 않는다 (내보낸 뒤 다시 초대하고 싶은 경우와 충돌, 데이터가 늘어남)

### 5.7 딥링크 — Universal Links / App Links만, 토큰은 라우터 밖에서 (T13)

- 커스텀 스킴(`travelcopilot://`)은 쓰지 않는다. 다른 앱이 같은 스킴을 등록해 토큰을 가로챌 수 있다
- iOS Universal Links: `apple-app-site-association` + 앱 entitlement `applinks:<도메인>`
- Android App Links: `assetlinks.json` + `intent-filter android:autoVerify="true"`
- 앱은 `app_links` 패키지로 링크를 받고, Flutter 기본 딥링크 처리는 끈다 (`FlutterDeepLinkingEnabled=false`)
  - 이유: 기본 처리는 URL을 go_router 경로로 넘기는데, 그러면 토큰이 라우터 상태·디버그 로그·화면 복원 데이터에 들어갈 수 있다
  - 토큰은 **메모리 provider**(`pendingInvite`)에만 두고, 경로는 `/invite`만 쓴다. 참여·취소·실패하면 즉시 버린다. 디스크에 쓰지 않는다
- 로그인이 필요하면: 토큰을 메모리에 둔 채 로그인 → 로그인 후 redirect가 `/invite`로 보낸다
- 붙여넣기 경로: 사용자가 붙여넣은 문자열에서 `/invite#` 뒤 토큰만 꺼낸다. 호스트가 `INVITE_BASE_URL`과 다르면 거절 (다른 사이트 링크를 붙여넣는 실수·피싱 방지)

### 5.8 안내 웹페이지(W01)와 확인 파일 — 같은 Nginx에서

| 경로 | 내용 |
|---|---|
| `/invite` | W01 정적 HTML. 앱 소개, 스토어 버튼 자리(출시 전엔 "준비 중"). **JavaScript 없음** — fragment를 읽거나 보내지 않는다 |
| `/.well-known/apple-app-site-association` | `application/json`, 리다이렉트 없이 |
| `/.well-known/assetlinks.json` | `application/json` |

- 파일은 `infra/web/`에 두고 Nginx가 정적으로 준다. 팀 ID·번들 ID·인증서 지문은 템플릿 값 (10절 준비물이 생기면 채움)
- W01에도 기존 보안 헤더(`no-store`, `nosniff`, `no-referrer`) + `Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; img-src 'self'`

## 6. API

| 메서드 | 경로 | 권한 | 설명 |
|---|---|---|---|
| POST | `/trips/{trip_id}/invites` | O (잠금) | 만들기 |
| GET | `/trips/{trip_id}/invites` | O | 목록 |
| DELETE | `/trips/{trip_id}/invites/{invite_id}` | O | 폐기 → 204 |
| POST | `/trips/{trip_id}/invites/revoke-all` | O | 열린 링크 모두 폐기 → `{ "revoked": 2 }` **(새로 추가)** |
| POST | `/invites/preview` | 👤 | 미리보기 |
| POST | `/invites/accept` | 👤 | 참여 |

**만들기**
```json
// 요청 (모두 생략 가능)
{ "role": "viewer", "max_uses": 10, "expires_in_days": 3 }
// 201 응답 — url은 이 응답에서만
{ "id": "…", "url": "https://localhost/invite#3fK…", "role": "viewer",
  "max_uses": 10, "use_count": 0, "expires_at": "2026-11-18T09:00:00Z", "status": "active" }
```

**목록 항목**: `id, role, max_uses, use_count, expires_at, revoked_at, created_at, created_by_name, status`
`status`: `active` | `expired` | `revoked` | `exhausted` (서버가 계산)

**미리보기·참여 요청**: `{ "token": "<43자>" }` (알 수 없는 필드 거절, 쿼리 문자열 토큰 거절)

**미리보기 응답**
```json
{ "trip_title": "파리 여행", "start_date": "2026-12-22", "end_date": "2026-12-29",
  "inviter_name": "홍길동", "role": "viewer", "already_member": false, "trip_id": null }
```

**참여 응답**: `200 { "trip_id": "…" }`

**에러**

| 상태 | code | 언제 |
|---|---|---|
| 404 | `not_found` | 토큰이 없거나 형식이 틀림, 남의 여행의 invite_id |
| 409 | `invite_limit` | 열린 링크 5개 상태에서 만들기 **(새 코드)** |
| 409 | `already_member` | 이미 멤버인데 참여 |
| 409 | `trip_member_limit` | 멤버 20명 **(새 코드)** |
| 410 | `invite_expired` / `invite_revoked` / `invite_exhausted` | 끝난 링크로 미리보기·참여 |
| 429 | `rate_limited` | 미리보기·참여 합쳐 사용자당 분당 10회 (06-api 5절) |

## 7. 데이터 변경

`invites` 테이블 (05-data-model 4절 그대로 + 제약):

| 컬럼 | 타입 | 제약 |
|---|---|---|
| id | uuid PK | |
| trip_id | uuid FK → trips ON DELETE CASCADE | 인덱스 |
| token_hash | char(64) | UNIQUE |
| role | enum `invite_role`(`editor`, `viewer`) | owner 불가를 타입으로 |
| max_uses | int | CHECK 1~20 |
| use_count | int default 0 | CHECK `0 <= use_count <= max_uses` |
| expires_at | timestamptz | |
| revoked_at | timestamptz NULL | |
| created_by | uuid FK → users ON DELETE SET NULL | |
| created_at | timestamptz | |

- 마이그레이션 1개, downgrade에서 enum까지 삭제 (F2·F3과 같은 방식)
- `use_count <= max_uses` CHECK는 원자적 증가가 깨졌을 때의 마지막 방어선

## 8. 보안 요구사항

| 위협 | 요구사항 | 확인 방법 (테스트) |
|---|---|---|
| T10 | 토큰 43자 URL-safe, 1,000개 생성 시 중복 없음 | `test_invite_token_entropy` |
| T10 | 미리보기·참여 사용자당 분당 10회 초과 → 429 | `test_invite_rate_limit` |
| T14 | DB 어느 컬럼에도 토큰 원문이 없고, `token_hash = sha256(토큰)` | `test_invite_stores_only_hash` |
| T11 | 만들기·목록·폐기·전체 폐기: editor·viewer 403, 비멤버 404 | `TRIP_ROUTE_CASES`에 추가 (라우트 전수 검사) |
| T11 | 폐기·만료·소진 링크로 미리보기·참여 → 410, 멤버 추가 안 됨 | `test_invite_ended_states` |
| T11 | 전체 폐기 후 내보낸 멤버가 옛 링크로 참여 불가 | `test_removed_member_cannot_rejoin_after_revoke_all` |
| T11 | 링크 역할은 editor·viewer만 (owner 요청 422), 기본 viewer | `test_invite_role_rules` |
| T11 | 토큰은 본문으로만: 쿼리로 보내면 422 | `test_invite_token_not_in_query` |
| T11 | 만들기·미리보기·참여 중 서버 로그(전 로거)에 토큰 원문 없음 | `test_invite_token_not_logged` |
| T12 | `max_uses=1` 링크에 서로 다른 5명이 동시에 참여 → 정확히 1명 성공, 나머지 410, `use_count=1` | `test_concurrent_accept_respects_max_uses` |
| T12 | 같은 사용자가 동시에 2번 참여 → 멤버십 1개, `use_count=1` | `test_concurrent_accept_same_user` |
| T12 | 멤버 19명에서 2명이 동시에 참여 → 1명만 성공 (`trip_member_limit`) | `test_concurrent_accept_member_limit` |
| T13 | 앱에 커스텀 스킴 등록 없음 (Info.plist `CFBundleURLTypes`에 초대용 스킴 없음, AndroidManifest에 `scheme` 커스텀 없음) | 앱 테스트 `deep_link_config_test` (설정 파일 검사) |
| T13 | 붙여넣기 링크의 호스트가 `INVITE_BASE_URL`과 다르면 거절, 토큰 형식 검사 | 앱 단위 `invite_link_parser_test` |
| T33 | 미리보기 응답 필드가 정해진 7개뿐 (멤버·일정·만료 정보 없음) | `test_invite_preview_fields` |
| — | W01에 `<script>`·인라인 이벤트 없음, CSP 헤더 | `test_invite_page_has_no_script` (파일 검사), CSP·응답 형식은 curl 수동 확인 (00 가이드 48·49) |

**방어 제거 시험** (구현 후 하나씩 빼서 테스트가 실패하는지 확인):
1. 참여의 조건부 UPDATE에서 `use_count < max_uses` 제거 → 동시 참여 테스트 실패 (CHECK 제약이 남아 있으면 500으로 실패해야 함 — 그것도 확인)
2. 원문 토큰을 저장 → 해시 저장 테스트 실패
3. owner 확인을 editor로 낮춤 → 권한 테스트 실패
4. 미리보기·참여 요청 제한 제거 → 429 테스트 실패

## 9. 앱

| 구분 | 내용 |
|---|---|
| 데이터 | `invites_api.dart` (만들기·목록·폐기·전체 폐기·미리보기·참여), 모델 freezed |
| 상태 | `invitesProvider(tripId)` (autoDispose), `pendingInviteProvider` (토큰, 메모리만) |
| S15 | 멤버 화면(owner)에서 진입. 만들기 시트(역할·횟수·기간, 편집자 경고), 만들면 `share_plus`로 공유 시트, 목록(상태 칩·폐기). 링크 공유 주의 문구: "링크를 받은 사람은 여행 제목과 날짜를 볼 수 있습니다" |
| S16 | `/invite`. 미리보기 → [참여]/[취소], 410·409·404 처리. 토큰은 화면에 표시하지 않음 |
| S03 | 메뉴에 [초대 링크로 참여] → 붙여넣기 입력 → S16 |
| S14 | 내보내기 대화상자에 "열린 초대 링크도 모두 폐기" (열린 링크가 있을 때만) |
| 딥링크 | `app_links`로 수신 → 파서 → `pendingInvite` → `/invite`. 로그인 redirect가 `pendingInvite`를 보고 로그인 후 `/invite`로 |
| 새 패키지 | `app_links`, `share_plus` |
| iOS | `FlutterDeepLinkingEnabled=false`. Associated Domains entitlement는 **P1(Apple Developer) 준비 후** 추가 (무료 계정은 이 기능을 켤 수 없고, 넣으면 빌드가 실패) |
| Android | `AndroidManifest`에 `https` + 호스트 `intent-filter autoVerify`. 호스트는 빌드 설정값 (도메인 전에는 비활성) |

## 10. 테스트 계획

- **서버 단위**: 토큰 생성·해시, 링크 상태 계산(active/expired/revoked/exhausted), 410 이유 우선순위
- **서버 API**: 만들기(기본값·범위·5개 상한), 목록(토큰 없음·30일 범위), 폐기(멱등), 전체 폐기, 미리보기(멤버/비멤버), 참여(성공·409·410·404)
- **보안**: 8절 표 전부 + 방어 제거 시험
- **앱**: 링크 파서(호스트·형식), S15 만들기→공유 호출·폐기, S16 미리보기·참여·410 문구, 로그인 거쳐 돌아오기(redirect), 내보내기 대화상자 체크박스, 딥링크 설정 검사
- **수동 확인** (iOS 시뮬레이터, 계정 2개 — 00 가이드의 가짜 멤버 방식 응용):
  1. owner로 링크 만들기 → 공유 시트 → [복사]
  2. 다른 계정으로 로그인 → [초대 링크로 참여] → 붙여넣기 → 미리보기 → 참여 → 목록에 여행
  3. 같은 링크 다시 → 바로 여행 상세
  4. 링크 폐기 → 붙여넣기 → "더 이상 쓸 수 없는 초대 링크"
  5. `https://localhost/invite` 브라우저로 열기 → W01, `/.well-known/…` 파일 응답

## 11. 개발자가 준비할 것

| # | 할 일 | 언제 필요 |
|---|---|---|
| — | 없음 | 이번 구현(서버·앱·붙여넣기 경로·설정 파일 템플릿)은 지금 상태로 진행 가능 |
| P1 | Apple Developer Program 가입 (연 $99) | iOS에서 링크를 눌러 앱이 바로 열리게 할 때 |
| P4 | 도메인(서브도메인)과 공인 HTTPS 서버 | Apple·Google이 확인 파일을 인터넷에서 가져가야 해서. 로컬 `localhost`·mkcert 인증서로는 검증 불가 |

## 12. 결정 사항 (2026-11-15 승인, 제안대로)

1. **링크로 앱 열기**: 이번에는 붙여넣기 경로로 전체 흐름을 완성하고, Universal Links·App Links는 설정 파일·코드만 준비. 실제 검증은 P1·P4·스테이징(P6) 때
2. **Android 확인**: F5를 마친 뒤 F1~F5를 한 번에 확인
3. **편집 권한 링크**: 경고 문구만 (사용 횟수 기본값은 역할과 관계없이 10)
4. **내보내기 시 링크 전체 폐기**: 체크박스, 기본 선택

## 함께 갱신할 문서 (구현 때)

- 06-api: 3.7에 `revoke-all` 추가, 에러 표에 `invite_limit`·`trip_member_limit`
- 05-data-model: invites 제약·CASCADE, 기본값(10회·3일) 확정 반영
- threat-model: T10~T14 상태, **T33 추가** (미리보기로 제목·날짜 노출 — 최소 필드로 줄이고 수용), 변경 이력
- roadmap: 2단계 초대 링크 항목 체크 (편집 권한 기본값 결정 포함)
- 00-getting-started: 초대 수동 확인 항목, 계정 2개 만드는 방법
- 09-tasks: F5 체크

## 13. 구현 결과 (2026-11-15)

**검증**: 서버 테스트 361개(F4 대비 +63, 권한 전수 검사 매개변수 포함), 앱 테스트 111개(+29) 통과. ruff·mypy·flutter analyze 통과. iOS 시뮬레이터 빌드 확인. 로컬 Nginx에서 W01(CSP·`no-store`·`<script>` 없음)과 확인 파일 2개(`application/json`, 리다이렉트 없음) 응답 확인. 개발 DB에 마이그레이션 적용

**만든 것**
- 서버 `invites/` 모듈: 모델·토큰(생성·해시·형식)·저장소·서비스·라우터, 마이그레이션(`invite_role` enum, CHECK 2개, downgrade에서 enum 삭제 — 왕복 확인)
- 설정: `INVITE_BASE_URL`(https만, 쿼리·fragment 금지), `INVITE_REDEEM_PER_MINUTE`(10)
- 끝난 초대 정리를 F4의 주기 작업(`run_periodically`)에 추가
- Nginx: `/invite`(W01), `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`. `infra/web/` 디렉터리 마운트 (단일 파일 마운트의 inode 문제 회피)
- 앱 `features/invites/`: 링크 파서, API, `pendingInvite`(메모리), `incomingLinks`(app_links), S15·S16, 여행 목록의 [초대 링크로 참여], 멤버 탭의 [초대 링크], 내보내기 대화상자의 전체 폐기 체크박스
- 앱 설정: `INVITE_BASE_URL`(env/*.json), iOS `FlutterDeepLinkingEnabled=false`, Android `flutter_deeplinking_enabled=false` + `https` App Link intent-filter(호스트는 gradle 속성 `inviteHost`, 기본 `invite.invalid`)

**방어 제거 시험**

| # | 뺀 방어 | 실패한 테스트 |
|---|---|---|
| 1 | 참여 UPDATE의 `use_count < max_uses` | `test_concurrent_accept_respects_max_uses` — 응답이 `[200, 500, 500, 500, 500]`. CHECK 제약이 마지막 방어선으로 막았고, 410이 아니라 500이라 테스트가 실패 |
| 2 | 토큰 해시 대신 원문 저장 | `test_invite_stores_only_hash` |
| 3 | owner 확인을 editor로 낮춤 | `test_non_owner_cannot_manage_invites[editor]` |
| 4 | 미리보기·참여 요청 제한 제거 | `test_invite_rate_limit` |

- 원복 후 파일이 원본과 같은지 `cmp`로 확인하고 전체 테스트를 다시 통과시켰다

**명세와 달라진 점·알아둘 점**
- 목록·정리 기준을 "끝난 지 30일"에서 "**만료된 지 30일**"로 바꿨다 (5.5). 소진된 시각은 기록하지 않기 때문
- 이미 멤버인 사람의 미리보기는 끝난 링크여도 410 대신 `already_member: true`와 `trip_id`를 준다 (바로 이동할 수 있게). 멤버가 아니면 410
- 기본 주소를 앱에서는 `inviteBaseUrlProvider`로 읽는다 (테스트에서 바꿔 끼우기 위해)
- 앱 테스트가 실제 버그를 하나 잡았다: S16에서 네트워크 오류 후 [다시 시도]가 성공해도 이전 오류 문구가 남아 미리보기를 가렸다 → 다시 불러올 때 오류 상태를 지우도록 수정
- `app_links`의 `uriLinkStream`이 앱 실행 링크(처음 링크)도 내보낸다는 동작은 실제 도메인이 생긴 뒤(P1·P4) 기기에서 확인한다
- iOS Associated Domains entitlement는 넣지 않았다 (무료 계정으로는 빌드 실패). P1 가입 후 추가
