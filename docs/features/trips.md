# F2. 여행·멤버

> 상태: 구현 완료 (2026-11-10) — 수동 확인·보안 점검 생략 (개발자 결정)
> 브랜치: `feat/trips`
> 관련 문서: [../05-data-model.md](../05-data-model.md) 4·5·6절, [../06-api.md](../06-api.md) 3.3·3.4절, [../07-screens.md](../07-screens.md) S03·S04·S05·S14
> 관련 위협: T06, T07, T08, T29
> 로드맵: 2단계 (인가)

## 1. 목적

여행을 만들고, 멤버가 역할(owner·editor·viewer)에 맞는 일만 할 수 있게 한다. 이 기능에서 만드는 **여행 권한 확인 의존성**은 이후 일정·초대·바우처 등 `/trips/{trip_id}/...` 아래 모든 API가 그대로 쓴다. "남의 여행에 접근할 수 있는 길"을 여기서 한 번에 막는 것이 핵심이다.

멤버를 **추가**하는 방법(초대 링크)은 F5에서 만든다. 이번에는 이미 멤버인 사람의 역할 변경·내보내기·나가기·소유권 넘기기만 만든다.

## 2. 사용자 시나리오

**여행 만들기**
1. 로그인하면 여행 목록(S03)이 나온다. 처음이면 빈 상태 안내 + "여행 만들기"
2. 제목, 목적지, 시작·종료일, 시간대를 입력해 저장 → 내가 owner인 여행이 생기고 여행 상세(S05)로 이동

**여행 보기·수정·삭제**
1. 목록에서 여행을 누르면 상세(S05): 제목, 기간, 내 역할, 탭 3개(일정·바우처·멤버)
2. owner·editor는 메뉴에서 "여행 수정" → S04에서 고쳐 저장. 그 사이 다른 멤버가 먼저 고쳤으면 "다른 멤버가 먼저 수정했습니다" + 최신 내용
3. owner는 "여행 삭제" → 제목을 다시 입력해야 삭제

**멤버 관리 (멤버 탭)**
1. 누구나 멤버 목록(이름, 역할, 참여일)을 본다
2. owner는 멤버의 역할을 editor ↔ viewer로 바꾸거나, 내보내거나, 소유권을 넘긴다 (넘기면 나는 editor가 됨)
3. editor·viewer는 "여행 나가기"를 할 수 있다. owner는 먼저 소유권을 넘겨야 나갈 수 있다

**내보내진 사람**
1. 다음 요청부터 그 여행의 모든 API가 404
2. 앱은 404를 받으면 "접근할 수 없는 여행입니다" → 목록으로. 목록을 새로고침하면 그 여행이 사라진다

## 3. 완료 조건

- [x] iOS 시뮬레이터에서 여행 만들기 → 목록·상세에 표시 (개발자 확인 2026-11-10)
- [ ] 여행 수정, 동시 수정 시 409 처리 화면 (수동 확인 생략, 개발자 결정 — 서버 API·위젯 테스트로 대체)
- [ ] 여행 삭제 (제목 재입력 확인) (수동 확인 생략, 개발자 결정 — 서버 API·위젯 테스트로 대체)
- [ ] 두 번째 사용자를 멤버로 넣어(00 가이드 5.1) 역할 변경·내보내기·소유권 넘기기·나가기 확인 (수동 확인 생략, 개발자 결정 — 서버 API·위젯 테스트로 대체)
- [x] 8절 보안 테스트 전부 통과, **권한 확인을 빼면 해당 테스트가 실패**하는 것 직접 확인 (13절)
- [x] 서버·앱 테스트, lint 통과, 실행 가이드(00) 갱신

## 4. 범위 밖

| 항목 | 시점 |
|---|---|
| 초대 링크로 멤버 추가 | F5 |
| 일정 탭 내용, 스냅샷의 일정 항목 | F3 (이번 스냅샷은 여행 정보 + 내 역할 + 멤버까지) |
| 기간을 줄였을 때 밀려나는 일정 검사 (`409`) | F3 (일정 테이블이 생길 때 추가) |
| 바우처 탭 내용, 멤버 내보내기 시 바우처 삭제 | F7 |
| 기기 캐시, 오프라인 표시, 목록에서 사라진 여행의 캐시 삭제 | F6 (이번 화면은 온라인 전용) |
| 사용자별 요청 횟수 제한 | F3 (F1 결정 유지) |
| 회원 탈퇴 시 소유권 자동 이전 | F9 |

## 5. 핵심 설계 결정

### 5.1 여행 권한 확인 의존성 `require_trip_member`

```python
TripViewer = Annotated[TripAccess, Depends(require_trip_member(TripRole.VIEWER))]
TripEditor = Annotated[TripAccess, Depends(require_trip_member(TripRole.EDITOR))]
TripOwner  = Annotated[TripAccess, Depends(require_trip_member(TripRole.OWNER))]
```

- 경로의 `trip_id`와 현재 사용자로 `trip_members`를 **요청마다** 조회한다 (캐시 없음 → 내보내면 다음 요청부터 바로 막힘, T08)
- 역할 서열: owner > editor > viewer. 최소 역할 이상이면 통과
- **멤버가 아니면 404 `not_found`** — 여행이 없을 때와 응답 본문까지 똑같이 (존재 여부를 숨김)
- **멤버인데 역할이 부족하면 403 `forbidden`**
- 통과하면 `TripAccess(trip, membership)`를 넘겨, 라우터·서비스가 여행을 다시 조회하지 않게 한다
- 서비스 계층의 쓰기 함수는 `TripAccess`를 인자로 받는다. 즉 권한 확인을 거치지 않은 채 여행을 수정하는 함수 호출 경로를 만들지 않는다

**라우트 전수 검사 테스트**: 앱에 등록된 모든 라우트 중 경로에 `{trip_id}`가 들어간 것은 의존성 트리에 `require_trip_member`가 반드시 있어야 한다. 새 API를 추가하면서 권한 확인을 빠뜨리면 이 테스트가 실패한다. F3 이후 기능도 자동으로 검사 대상이 된다.

### 5.2 owner는 항상 정확히 1명

- DB: `trip_members`에 부분 UNIQUE 인덱스 `(trip_id) WHERE role = 'owner'` → 두 번째 owner는 DB가 거절
- 소유권 넘기기는 한 트랜잭션에서 **여행 행을 잠그고**(`SELECT ... FOR UPDATE`) 기존 owner를 editor로 낮춘 다음 대상을 owner로 올린다. 같은 여행에 대한 동시 넘기기·역할 변경은 잠금 때문에 순서대로 처리된다
- 역할 변경 API는 `editor`·`viewer`만 받는다. `owner`를 보내면 422. owner의 역할은 이 API로 바꿀 수 없다 (409 `owner_role_locked`)

### 5.3 동시 수정 (T29)

- 여행 수정·삭제는 `version` 필수. 서버 값과 다르면 `409 version_conflict` + 본문 `current`에 최신 여행 정보
- 수정은 `UPDATE ... WHERE id = :id AND version = :version` 한 문장으로 확인과 증가를 같이 한다 (읽고 비교한 뒤 쓰는 사이의 경쟁 없음)
- 삭제는 본문 대신 쿼리 `DELETE /trips/{id}?version=3`
- **멤버 API에는 `version`을 두지 않는다.** owner 한 명만 하는 작업이고, 결과가 "최종 상태"라서 (예: viewer로 바꾸기를 두 번 해도 같음). 동시성은 5.2의 여행 행 잠금으로 처리

### 5.4 여행 목록 정렬과 페이지

- 정렬: `start_date DESC, id DESC` (최근 여행이 위). 커서는 마지막 항목의 `(start_date, id)`를 인코딩한 불투명 문자열
- `limit` 기본 20, 최대 50
- 앱은 새로고침 때 `next_cursor`가 없을 때까지 모두 받는다 (사용자 한 명의 여행 수는 많지 않고, F6에서 "목록에 없는 여행 캐시 삭제"를 하려면 전체 목록이 필요)
- 앱에서 "다가오는 여행"(종료일 ≥ 오늘, 시작일 오름차순)과 "지난 여행"(종료일 내림차순)으로 나눠 보여준다

### 5.5 입력 검증

| 필드 | 규칙 |
|---|---|
| `title`, `destination` | 앞뒤 공백 제거 후 1~100자. 줄바꿈 등 제어 문자 거절 |
| `start_date`, `end_date` | `start_date ≤ end_date`, 기간 최대 60일 (양 끝 포함) |
| `timezone` | IANA 이름 (`Asia/Seoul`, `Europe/Paris`). 서버의 시간대 목록에 있어야 함. 서버 이미지에 `tzdata` 패키지를 넣어 OS에 의존하지 않음 |

- 과거 날짜 여행도 만들 수 있다 (지난 여행 기록용)

### 5.6 응답 캐시 금지

API 공통 규칙(`Cache-Control: no-store`)이 아직 서버에 없다. 여행부터 개인정보(기간 = 집이 비는 때, 멤버 이름)가 오가므로 이번에 **모든 API 응답**에 붙이는 미들웨어를 추가한다.

### 5.7 멤버 정보 노출 범위

멤버 목록에는 `user_id`, `display_name`, `role`, `joined_at`만 담는다. **다른 멤버의 이메일은 보내지 않는다** (여행 멤버라고 해서 연락처까지 공유하는 건 아님).

## 6. API

| 메서드 | 경로 | 권한 | 성공 |
|---|---|---|---|
| GET | `/trips` | 👤 | 200 목록 |
| POST | `/trips` | 👤 | 201 여행 (만든 사람이 owner) |
| GET | `/trips/{trip_id}` | V 이상 | 200 스냅샷 |
| PATCH | `/trips/{trip_id}` | E 이상 | 200 여행 |
| DELETE | `/trips/{trip_id}?version=N` | O | 204 |
| PATCH | `/trips/{trip_id}/members/{user_id}` | O | 200 멤버 |
| DELETE | `/trips/{trip_id}/members/{user_id}` | O(내보내기) 또는 본인(나가기) | 204 |
| POST | `/trips/{trip_id}/transfer-ownership` | O | 200 스냅샷 |

**여행 객체** (목록 항목, 생성·수정 응답)

```json
{
  "id": "6f1c…",
  "title": "파리 가족여행",
  "destination": "프랑스 파리",
  "start_date": "2026-12-20",
  "end_date": "2026-12-27",
  "timezone": "Europe/Paris",
  "version": 1,
  "my_role": "owner",
  "member_count": 3,
  "updated_at": "2026-11-08T03:00:00Z"
}
```

**목록**: `GET /trips?cursor=…&limit=20` → `{ "items": [여행 객체…], "next_cursor": "…" | null }`

**생성**: `POST /trips` `{ title, destination, start_date, end_date, timezone }`

**수정**: `PATCH /trips/{id}` `{ version, title?, destination?, start_date?, end_date?, timezone? }` — 바꿀 필드만. 하나도 없으면 422

**스냅샷**: `GET /trips/{id}`

```json
{
  "trip": { "…여행 객체…" },
  "members": [
    { "user_id": "…", "display_name": "손옥무", "role": "owner", "joined_at": "2026-11-08T03:00:00Z" }
  ]
}
```

F3부터 `items`(일정), F7부터 `vouchers`가 같은 응답에 추가된다.

**역할 변경**: `PATCH /trips/{id}/members/{user_id}` `{ "role": "editor" | "viewer" }`

**소유권 넘기기**: `POST /trips/{id}/transfer-ownership` `{ "user_id": "…" }`

**에러**

| 상황 | 응답 |
|---|---|
| 비멤버, 없는 여행 | 404 `not_found` (둘이 구별되지 않음) |
| 역할 부족 (viewer가 수정, editor가 삭제·멤버 관리 등) | 403 `forbidden` |
| `version` 불일치 | 409 `version_conflict` + `current` |
| owner가 나가기 (자기 자신 DELETE) | 409 `owner_cannot_leave` |
| owner의 역할 변경 시도 | 409 `owner_role_locked` |
| 대상 사용자가 이 여행의 멤버가 아님 (역할 변경·내보내기·넘기기) | 404 `not_found` |
| 자기 자신에게 소유권 넘기기 | 400 `invalid_request` |
| 검증 실패, 정의되지 않은 필드, `role: "owner"` | 422 `validation_error` |

## 7. 데이터 변경

마이그레이션 1개: `create_trip_tables`

**trips** — 05-data-model.md 4절 그대로
- CHECK `start_date <= end_date`
- 60일 상한은 API 검증에서

**trip_members**
- PK `(trip_id, user_id)`
- `trip_id` FK → trips `ON DELETE CASCADE` (여행 삭제 시 멤버 삭제)
- `user_id` FK → users `ON DELETE CASCADE` (탈퇴 처리 순서는 F9에서 서비스가 따로 보장)
- `role` enum `trip_role` (`owner`, `editor`, `viewer`)
- 부분 UNIQUE 인덱스 `uq_trip_members_one_owner ON (trip_id) WHERE role = 'owner'`
- 인덱스 `(user_id)` — 내 여행 목록 조회용

## 8. 보안 요구사항

| 위협 | 요구사항 | 확인 방법 (테스트) |
|---|---|---|
| T06 | `{trip_id}`가 있는 모든 라우트에 권한 확인 의존성 | `test_all_trip_routes_require_membership` (라우트 전수 검사) |
| T06 | 비멤버가 남의 여행 조회·수정·삭제·멤버 API 호출 → 404 | `test_non_member_gets_404_on_every_trip_route` (모든 trip 라우트 × 비멤버) |
| T06 | 비멤버 404와 없는 여행 404의 응답 본문이 같음 | `test_non_member_and_missing_trip_responses_are_identical` |
| T06 | 여행 목록에 내가 멤버인 여행만 나옴 | `test_list_trips_returns_only_my_trips` |
| T07 | viewer가 여행 수정 → 403 | `test_viewer_cannot_update_trip` |
| T07 | editor가 여행 삭제·역할 변경·내보내기·소유권 넘기기 → 403 | `test_editor_cannot_*` |
| T07 | editor·viewer가 다른 멤버를 DELETE (본인 아님) → 403 | `test_member_cannot_remove_other_member` |
| T07 | 요청 본문에 `role`, `owner_id` 등을 끼워 넣어도 무시가 아니라 422 | `test_trip_create_with_extra_fields_returns_422` |
| T07 | 역할 변경으로 `owner` 지정 불가 | `test_change_role_to_owner_returns_422` |
| T08 | 내보낸 멤버가 이전 여행 ID로 접근 → 404 | `test_removed_member_gets_404` |
| T08 | 나간 멤버가 다시 접근 → 404 | `test_left_member_gets_404` |
| T08 | 넘기기 뒤 이전 owner는 owner 전용 API에서 403 | `test_former_owner_loses_owner_actions` |
| T29 | `version`이 다르면 409, 덮어쓰지 않음 | `test_update_trip_with_stale_version_returns_409` |
| T29 | owner 두 명 불가 (DB 제약) | `test_second_owner_rejected_by_db` |
| T29 | 동시 소유권 넘기기 2건 → owner는 정확히 1명 | `test_concurrent_transfers_keep_single_owner` |
| — | 모든 응답에 `Cache-Control: no-store` | `test_responses_have_no_store` |
| — | 멤버 목록에 다른 사람의 이메일 없음 | `test_snapshot_members_exclude_email` |

**방어 제거 시험** (F1과 같은 방식, 커밋하지 않음): 아래를 하나씩 꺼서 해당 테스트가 실패하는지 확인하고 결과를 이 문서에 기록한다.
1. 특정 라우트에서 `require_trip_member` 제거 → 전수 검사·비멤버 404 테스트 실패
2. 역할 비교를 항상 통과로 → T07 테스트 실패
3. 부분 UNIQUE 인덱스 제거 + 잠금 제거 → owner 중복 테스트 실패
4. `UPDATE`의 `version` 조건 제거 → 409 테스트 실패

## 9. 앱

| 항목 | 내용 |
|---|---|
| 라우트 | `/trips`(S03, 로그인 후 첫 화면), `/trips/new`, `/trips/:id`, `/trips/:id/edit`. 임시 홈(`/home`)은 삭제 |
| 데이터 (`features/trips/data`) | freezed 모델(Trip, TripSnapshot, TripMember, TripDraft), `TripRole` enum, `TripsApi`(dio, 목록 전체 받기 포함 — 별도 저장소 계층은 F6 캐시 때 추가), 입력 규칙 `TripRules` |
| 상태 (`features/trips/state`) | 여행 목록 provider(전체 페이지 받기), 여행 스냅샷 provider(여행별), 수정 작업 후 관련 provider 무효화 |
| S03 여행 목록 | "다가오는 여행" / "지난 여행" 구역. 카드: 제목, 목적지, 기간(예: 12월 20일 ~ 27일 · 8일), 내 역할. 당겨서 새로고침. 빈 상태 안내. 오른쪽 위에 로그아웃(설정 화면은 F9) |
| S04 만들기·수정 | 제목, 목적지, 시작·종료일(날짜 선택), 시간대(검색 가능한 목록, **기본값 빈칸**). 클라이언트 검증은 서버와 같은 규칙. 시간대 목록은 `timezone` 패키지의 IANA 데이터 사용 |
| S05 상세 | 상단: 제목, 기간, 내 역할. 탭: 일정(“F3에서 추가됩니다” 자리표시) / 바우처(자리표시) / 멤버. 메뉴: 수정(O E), 삭제(O, 제목 재입력), 나가기(E V) |
| S14 멤버 (S05의 멤버 탭) | 목록: 이름, 역할, 참여일, "나" 표시. owner: 각 멤버 메뉴에서 역할 변경·내보내기(확인 대화상자)·소유권 넘기기(확인 대화상자). editor·viewer: "여행 나가기". owner에게 "내보낸 사람의 기기에 남은 데이터는 다음 동기화 때 지워집니다" 안내 |
| 권한별 버튼 | 내 역할에 따라 숨김. 막는 것은 서버 (화면 숨김은 편의) |
| 에러 처리 (07-screens 5절) | `403` → "권한이 없습니다" + 스냅샷 새로고침 / `404` → "접근할 수 없는 여행입니다" → 목록 / `409 version_conflict` → 최신 내용 표시 + [내 수정 다시 적용] [취소] / 네트워크 오류 → "저장되지 않았습니다" |

## 10. 테스트 계획

- **서버 단위**: 역할 서열 비교, 입력 검증(제목·기간 60일·시간대), 커서 인코딩·디코딩(변조된 커서 → 422)
- **서버 API** (필수 5종): 6절의 모든 엔드포인트 — 토큰 없음 401, 비멤버 404, 역할 부족 403, 정의되지 않은 필드 422, 정상 응답 형식. 목록 페이지 넘기기, 삭제 시 멤버도 삭제
- **보안**: 8절 테스트 전부 (`tests/security/test_trips_authz.py`)
- **앱**: 모델 JSON 변환, 목록 구역 나누기(다가오는·지난), 폼 검증, 역할별 버튼 표시, 409 처리, 404 시 목록 이동
- **수동 확인 (iOS 시뮬레이터)**
  1. 여행 만들기 → 목록·상세 표시
  2. 여행 수정 → 반영. curl로 먼저 수정해 version을 올린 뒤 앱에서 저장 → 409 화면
  3. 두 번째 사용자 넣기: 00 가이드에 넣을 SQL로 가짜 사용자를 만들어 editor로 추가 → 멤버 탭에 표시 → 역할 변경·내보내기·소유권 넘기기
  4. 소유권을 가짜 사용자에게 넘긴 뒤 내 계정으로 삭제 메뉴가 사라지고, 나가기가 되는지
  5. 여행 삭제 (제목 재입력)

## 11. 서버 설정·의존성 추가

| 항목 | 내용 |
|---|---|
| `tzdata` (서버 의존성) | IANA 시간대 데이터. slim 이미지에 OS 시간대 데이터가 없어도 검증되게 |
| `timezone` (앱 의존성) | 시간대 선택 목록 |
| 환경변수 | 추가 없음 |

## 12. 열린 질문

- 여행 목록 카드의 "바우처 준비 상태"(받아둔 수 / 전체)는 F8에서 추가
- 멤버 상한(20명) 검사는 멤버가 늘어나는 F5(초대 수락)에서 적용

## 13. 구현 결과 (2026-11-08)

**테스트**: 서버 176개(F2 추가 99개, 파라미터별 포함), 앱 55개(F2 추가 23개) 통과. lint·타입 검사 통과.

**방어 제거 시험** (하나씩 끄고 실행 → 되돌림, 커밋하지 않음)

| # | 끈 것 | 실패한 테스트 |
|---|---|---|
| 1a | 권한 확인 없는 `GET /trips/{trip_id}/leak` 라우트 추가 | `test_all_trip_routes_require_membership`, `test_trip_route_cases_cover_all_routes` |
| 1b | 비멤버도 owner로 취급 | 비멤버 404 × 6 라우트, 응답 동일성 × 6, 내보낸·나간 멤버 404 (14개) |
| 2 | 역할 비교 항상 통과 | viewer 수정, editor·viewer의 owner 작업 6종, 이전 owner, 동시 넘기기 (9개) |
| 3 | owner 부분 UNIQUE 인덱스 + 잠금 제거 | `test_second_owner_rejected_by_db`, `test_concurrent_transfers_keep_single_owner` |
| 3b | 잠금만 제거 | `test_concurrent_transfers_keep_single_owner` |
| 4 | `UPDATE`의 version 조건 + 사전 비교 제거 | stale version 409, 동시 수정 5건 중 1건만 성공 |

- 처음 쓴 동시 소유권 넘기기 테스트(요청 2개를 동시에 보냄)는 잠금을 꺼도 통과했다. 테스트 안에서 두 요청이 사실상 순서대로 처리돼 경쟁이 생기지 않았기 때문. 테스트가 직접 여행 행을 잠근 채 다른 트랜잭션이 소유권을 넘기는 상황을 만들도록 바꿨고, 3·3b에서 실패하는 것을 확인했다
- 시험 1a 첫 실행에서 관련 없는 `test_editor_can_update_trip`이 한 번 실패했다. 이후 전체 6회, 해당 파일 15회 반복에서 재현되지 않아 원인을 특정하지 못했다. 다시 나타나면 조사한다

**명세와 달라진 점**
- 라우트 전수 검사: 이 FastAPI 버전은 `app.routes`에 포함된 라우터를 내부 객체로 감싸 개별 라우트가 보이지 않는다. 그래서 `main.ROUTERS`(앱에 등록하는 라우터 목록)를 검사하고, 앱의 OpenAPI 스키마에 나온 `{trip_id}` 경로와 같은지도 대조한다 (목록 밖에서 등록한 라우트도 잡힘)
- `Cache-Control: no-store`: Nginx도 같은 헤더를 붙이고 있어 응답에 두 번 나갔다. 서버 미들웨어는 유지하고(Nginx 없이도 보장, 테스트로 확인), Nginx는 `proxy_hide_header Cache-Control`로 서버 값을 숨기고 자기 헤더 하나만 보낸다 (Nginx가 직접 만드는 502 등에도 붙어야 해서)
- 앱 `TripsRepository`는 만들지 않고 `TripsApi`에 목록 전체 받기를 넣었다. 지금은 전달만 하는 계층이라 F6(기기 캐시)에서 필요할 때 추가한다
- 시간대 목록에서 `Etc/GMT+9`처럼 부호가 반대로 읽히는 이름은 뺐다 (서버는 받음)
