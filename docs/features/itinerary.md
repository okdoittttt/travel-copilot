# F3. 일정·장소 검색

> 상태: 구현 완료 (2026-11-10) — 실제 Places 키로 수동 확인 대기
> 브랜치: `feat/trips` (작업 브랜치 하나를 계속 사용)
> 관련 문서: [../05-data-model.md](../05-data-model.md) 2·4절, [../06-api.md](../06-api.md) 3.5·3.6·5절, [../07-screens.md](../07-screens.md) S06·S08·S09·S10
> 관련 위협: T06, T20, T23, T29, T32(신규)
> 로드맵: 2단계 (시큐어코딩, 외부 API)

## 1. 목적

여행 기간의 날짜마다 일정 항목(제목, 장소, 시각, 메모)을 만들고 순서를 정할 수 있게 한다. 장소는 Google Places로 검색하되, **Google API 키는 서버에만 두고 서버가 대신 호출**한다.

이 기능에서 처음으로 돈이 드는 외부 API를 쓴다. 그래서 요금 폭탄 방지(사용자별 호출 제한, 필드 마스크, 세션 토큰)와 Google 약관(무엇을 저장할 수 있나)이 설계의 중심이다.

## 2. 사용자 시나리오

**일정 보기**
1. 여행 상세의 "일정" 탭 → 위쪽에 여행 날짜 목록, 아래에 고른 날의 항목들
2. 항목마다 시작 시각, 제목, 머무는 시간, 메모가 보인다

**일정 추가 (owner·editor)**
1. "+ 추가" → 항목 입력 화면(S09). 제목은 필수, 나머지는 선택
2. "장소 선택" → 장소 검색(S08). 검색어를 치면 잠깐 멈춘 뒤 자동완성 결과가 나온다
3. 장소를 고르면 입력 화면으로 돌아오고, 제목 칸 아래에 "Google 장소 이름: 오르세 미술관 [이 이름 사용]" 힌트가 보인다
4. 저장 → 그날 맨 뒤에 추가

**순서 바꾸기·삭제 (owner·editor)**
1. 항목을 길게 눌러 끌어서 순서 변경 → 서버에 그날 전체 순서를 한 번에 저장
2. 항목을 밀어서 삭제 (확인 대화상자)

**장소 정보**
1. 장소가 있는 항목을 누르면 아래에서 장소 정보 시트(S10): 주소, "Google 지도에서 열기", Google 출처 표시

**viewer**: 보기만. 추가 버튼·순서 변경·삭제가 없고, 항목을 누르면 읽기 전용 화면

## 3. 완료 조건

- [ ] iOS 시뮬레이터에서 장소 검색 → 항목 추가 → 일정 탭에 표시 (실제 Google 키 사용)
- [ ] 순서 변경, 다른 날로 옮기기, 삭제
- [x] 여행 기간을 줄여 밀려나는 항목이 있으면 409 (F2에서 미룬 것) — 서버 테스트·curl 확인
- [x] 8절 보안 테스트 전부 통과, 방어 제거 시험 (13절)
- [x] 서버·앱 테스트, lint 통과, 실행 가이드(00) 갱신

## 4. 범위 밖

| 항목 | 시점 |
|---|---|
| 이동시간(legs), `GET /trips/{id}/days/{date}` | F4 (Google Routes) |
| 일정 지도(S07) | F4 |
| 오프라인 일정 보기, 기기 캐시 | F6 |
| 계획 시각과 이동시간이 안 맞을 때 주황색 경고 | F4 (이동시간이 있어야 계산 가능) |
| 좌표 30일 정리 작업의 **자동 실행(스케줄)** | 운영 배포 (로드맵 5단계). 이번엔 정리 명령과 테스트까지 |
| 특정 위치에 끼워 넣기 (`POST`의 `position`) | 빼기로 함 (5.3). 추가는 항상 맨 뒤, 위치는 순서 변경으로 |

## 5. 핵심 설계 결정

### 5.1 Google Places 호출 — 요금 등급을 낮게

| 호출 | Google API | 요청 필드 | 요금 등급 |
|---|---|---|---|
| 자동완성 | `POST places:autocomplete` | 장소 ID, 장소 이름(`mainText`), 보조 설명(`secondaryText`) | Autocomplete Requests (월 10,000회 무료). Essentials로 끝난 세션은 **처음 12회만 과금**, 13회째부터 무료 |
| 장소 선택 (세션 종료) | `GET places/{id}` + 세션 토큰 | `id`, `formattedAddress`, `location` | Place Details Essentials (월 10,000회 무료, 이후 1,000회당 $5) |
| 장소 정보 시트 | `GET places/{id}` (세션 없음) | `id`, `formattedAddress`, `location` (위와 같은 마스크) | Place Details Essentials |

- **장소 이름(`displayName`)은 장소 상세에서 요청하지 않는다.** Pro 등급 필드라 하나만 넣어도 호출 전체가 Pro 요금(월 5,000회 무료, 이후 1,000회당 $17)이 된다. 게다가 **세션을 Pro 필드로 끝내면 그 장소 상세는 가장 비싼 Enterprise + Atmosphere(월 1,000회 무료, 1,000회당 $25)로 과금**된다 (대신 그 세션의 자동완성은 무료)
  - S09의 "Google 장소 이름" 힌트는 **자동완성 결과의 이름**(`mainText`)을 쓴다. 이미 받은 값이라 추가 비용이 없다
  - S10 장소 정보 시트의 제목은 **사용자가 저장한 일정 제목**을 쓴다
- **"Google 지도에서 열기" 링크는 서버가 `place_id`로 만든다** (`https://www.google.com/maps/search/?api=1&query=...&query_place_id=...`, Google 공식 Maps URLs 형식). `googleMapsUri` 필드는 Pro 등급이라 요청하지 않는다
- 필드 마스크(`X-Goog-FieldMask`)는 서버 코드에 상수로 고정한다. 요청 값으로 바꿀 수 없다
- 응답 언어 `languageCode=ko`
- 요금 등급과 금액은 2026-11-10 공식 페이지로 확인했다 ([SKU 상세](https://developers.google.com/maps/billing-and-pricing/sku-details/places), [데이터 필드](https://developers.google.com/maps/documentation/places/web-service/data-fields), 세션 요금 문서). 계산: 검색 한 번에 자동완성 약 5회 + 장소 상세 1회 → 둘 다 월 10,000회 무료 범위에서 처리

### 5.2 세션 토큰과 좌표 — 두 번 돈 내지 않기

장소를 고르는 흐름:
1. 앱이 S08에 들어올 때 세션 토큰(무작위 128비트)을 만든다
2. 자동완성 요청마다 같은 토큰을 보낸다
3. 장소를 고르면 앱이 `GET /places/{place_id}?session_token=...` → 서버가 Google 장소 상세를 같은 토큰으로 호출 (여기서 세션이 끝난다. 세션으로 묶어야 13회째부터 무료가 되고, 세션 없이 부르면 모든 자동완성이 과금된다)
4. 서버는 받은 좌표를 **메모리에 10분 보관**한다 (키: 사용자 ID + place_id)
5. 앱이 `POST /trips/{id}/items`에 `place_id`만 보내면, 서버는 4의 좌표를 쓴다. 없으면(10분 지남, 서버 재시작) 서버가 장소 상세를 한 번 더 호출해 좌표를 받는다

- **앱이 보낸 좌표는 받지 않는다.** 저장되는 좌표는 항상 서버가 Google에서 직접 받은 값이다 (Google 응답만 신뢰, 조작된 좌표가 다른 멤버 화면에 퍼지지 않게)
- 좌표의 메모리 보관은 약관상 허용(좌표는 30일까지 저장 가능)이고, 이름·주소는 보관하지 않는다

### 5.3 일정 항목 순서

- 항목은 `(trip_id, day, position)`으로 정렬. UNIQUE 제약은 **트랜잭션 끝에 검사(DEFERRABLE)**해서, 순서를 바꾸는 도중 잠깐 겹치는 상태를 허용한다
- **추가는 항상 그날 맨 뒤.** 특정 위치에 끼워 넣기는 순서 변경으로 한다 (API 단순화. 06-api의 `POST`에서 `position` 제거)
- 하루 순서 변경 `PUT /days/{date}/order`: 그날의 **모든 항목 ID와 version**이 정확히 들어 있어야 한다
  - 빠진 항목, 다른 날·다른 여행의 항목, 중복이 있으면 `409 order_mismatch` + 그날의 최신 항목 목록
  - version이 하나라도 다르면 `409 version_conflict` + 최신 목록
  - 위치가 바뀐 항목만 version을 올린다
- 다른 날로 옮기기(`PATCH`의 `day`): 새 날의 맨 뒤에 붙고, 원래 날은 빈자리를 당겨 0부터 다시 번호를 매긴다
- 삭제도 빈자리를 당긴다
- 항목을 추가·이동·삭제·순서 변경하는 요청은 **여행 행을 잠그고** 처리한다 (F2의 잠금 의존성 재사용). 동시에 두 명이 같은 날에 추가해도 position이 겹치지 않는다
- 하루 최대 50개 → 넘으면 `409 day_item_limit`

### 5.4 Google 데이터 저장 규칙 (약관)

| 데이터 | 처리 |
|---|---|
| `place_id` | 일정 항목에 저장 (기한 없음) |
| 좌표 | 일정 항목에 저장 + `location_fetched_at`. **30일이 지난 좌표는 응답에 넣지 않고**, 정리 명령이 DB에서 지운다 |
| 장소 이름·주소 | 저장하지 않는다. 화면에 보여줄 때마다 받는다 |
| 일정 제목 | 사용자가 입력하거나 [이 이름 사용]으로 **확정한** 값만 저장 (05-data-model 9절 회색지대 대응 유지) |

- 정리 명령: `python -m travel_copilot.jobs.expire_locations` — 30일 지난 좌표를 NULL로. 자동 실행 스케줄은 운영 배포 때 (4절)
- F4에서 이동시간을 계산할 때 좌표가 없으면 그때 장소 상세로 다시 받는다

### 5.5 사용자별 요청 횟수 제한 (F1에서 F3로 미룬 것)

06-api 5절 그대로. 기존 IP 기준 제한기를 사용자 기준으로도 쓸 수 있게 확장한다.

| 대상 | 기준 | 제한 |
|---|---|---|
| `GET /places/autocomplete` | 사용자 | 분당 60회 + 하루 1,000회 |
| `GET /places/{place_id}` | 사용자 | 하루 300회 |
| 그 외 로그인 필요 API 전부 | 사용자 | 분당 120회 |

- 서버 메모리 기준이라 서버를 재시작하면 초기화된다. 마지막 방어선은 Google Cloud 할당량 상한(개발자가 설정 완료)이다
- 앱의 자동완성은 입력이 0.3초 멈췄을 때만, 2글자 이상일 때만 호출한다

### 5.6 Google 요청을 조작하지 못하게 (T32, 신규 위협)

`place_id`는 Google 요청 URL 경로(`/v1/places/{place_id}`)에 들어간다. `../` 같은 값이 들어가면 의도하지 않은 Google API를 부를 수 있다.

- `place_id`: `^[A-Za-z0-9_-]{1,255}$`만 허용. 서버 경로·요청 본문 어디서 받든 같은 규칙
- `session_token`: `^[A-Za-z0-9_-]{16,64}$`
- 검색어 `q`: 1~100자, 앞뒤 공백 제거
- 위 검증에 실패하면 **Google을 호출하지 않고** 422
- Google 호출은 정해진 두 주소(`places:autocomplete`, `places/{id}`)로만. 주소를 요청 값으로 조립하지 않는다

### 5.7 Google 응답도 외부 입력

- 응답을 Pydantic 모델로 검증한다: `place_id` 형식, 위도 -90~90·경도 -180~180, 문자열 길이 상한
- 형식이 맞지 않는 결과는 버린다 (자동완성은 그 항목만 빼고, 장소 상세는 502)
- Google 에러 응답 본문은 **우리 응답에 넣지 않는다.** 서버 로그에 상태 코드만 남기고 앱에는 `502 upstream_error`
- API 키는 요청 헤더(`X-Goog-Api-Key`)로만 보낸다. URL 쿼리에 넣지 않는다 (URL은 로그·프록시에 남기 쉬움)
- 타임아웃: 기존 외부 호출 설정(전체 10초, 연결 3초)

### 5.8 API 키가 없을 때

`GOOGLE_PLACES_API_KEY`가 비어 있으면 서버는 정상으로 뜨고, 장소 API만 `503 places_unavailable`을 돌려준다. 일정 항목(장소 없이 메모만)은 키 없이도 쓸 수 있다. 테스트와 키 없는 개발 환경을 위해서다.

## 6. API

### 6.1 일정 항목

| 메서드 | 경로 | 권한 | 성공 |
|---|---|---|---|
| POST | `/trips/{trip_id}/items` | E 이상 | 201 항목 |
| PATCH | `/trips/{trip_id}/items/{item_id}` | E 이상 | 200 항목 |
| DELETE | `/trips/{trip_id}/items/{item_id}?version=N` | E 이상 | 204 |
| PUT | `/trips/{trip_id}/days/{date}/order` | E 이상 | 200 그날 항목 목록 |
| GET | `/trips/{trip_id}` | V 이상 | 스냅샷에 `items` 추가 (전체 날짜) |

**항목 객체**

```json
{
  "id": "…",
  "day": "2026-12-24",
  "position": 1,
  "title": "오르세 미술관",
  "memo": "목요일 야간 개장",
  "place_id": "ChIJ…",
  "location": { "lat": 48.86, "lng": 2.3266 },
  "start_time": "10:00",
  "stay_minutes": 180,
  "travel_mode": "transit",
  "version": 1,
  "updated_at": "2026-11-10T03:00:00Z"
}
```

- `location`은 30일이 지났거나 장소가 없으면 `null`
- 작성자·수정자(`created_by`, `updated_by`)는 DB에만 두고 응답에는 넣지 않는다 (지금 화면에서 쓰지 않음)

**추가**: `POST` `{ day, title, memo?, place_id?, start_time?, stay_minutes?, travel_mode? }` → 그날 맨 뒤

**수정**: `PATCH` `{ version, 바꿀 필드… }`
- `title`, `day`에 `null` 불가 (값이 꼭 있어야 하는 필드)
- `memo`, `place_id`, `start_time`, `stay_minutes`, `travel_mode`에 `null`을 보내면 **지우기** (F2의 여행 수정과 다름: 여행 필드는 모두 필수라 `null`이 의미가 없었음)
- `place_id`를 바꾸면 좌표도 서버가 새로 받는다 (5.2), 지우면 좌표도 지운다

**순서 변경**: `PUT /days/{date}/order` `{ "items": [{ "id", "version" }, …] }` → `{ "date", "items": [항목…] }`

**입력 규칙**

| 필드 | 규칙 |
|---|---|
| `day` | 여행 기간 안의 날짜 |
| `title` | 앞뒤 공백 제거 후 1~100자, 제어 문자 거절 |
| `memo` | 최대 1,000자. 줄바꿈 허용, 그 외 제어 문자 거절 |
| `start_time` | `HH:MM` (24시간) |
| `stay_minutes` | 0~1440 |
| `travel_mode` | `drive`, `transit`, `walk` |

### 6.2 장소

| 메서드 | 경로 | 권한 | 성공 |
|---|---|---|---|
| GET | `/places/autocomplete?q=&session_token=&lat=&lng=` | 👤 | 200 |
| GET | `/places/{place_id}?session_token=` | 👤 | 200 |

```json
// GET /places/autocomplete?q=오르세 → 200
{
  "suggestions": [
    { "place_id": "ChIJ…", "name": "오르세 미술관", "secondary": "프랑스 파리" }
  ],
  "attribution": "Google Maps"
}

// GET /places/ChIJ…?session_token=… → 200
{
  "place_id": "ChIJ…",
  "address": "1 Rue de la Légion d'Honneur, 75007 Paris, 프랑스",
  "location": { "lat": 48.86, "lng": 2.3266 },
  "maps_url": "https://www.google.com/maps/search/?api=1&query=…&query_place_id=ChIJ…",
  "attribution": "Google Maps"
}
```

- `lat`·`lng`(선택): 결과를 이 근처로 치우치게 한다 (반경 50km). 앱은 그날 일정 중 좌표가 있는 첫 항목을 보낸다. 없으면 생략
- 장소 API는 여행과 무관해서 여행 권한 확인이 없다. 로그인만 필요하고, 사용자별 호출 제한으로 막는다

### 6.3 에러

| 상황 | 응답 |
|---|---|
| 비멤버, 다른 여행의 항목 ID | 404 `not_found` |
| viewer가 추가·수정·삭제·순서 변경 | 403 `forbidden` |
| 항목 version 불일치 | 409 `version_conflict` + `current` (항목, 순서 변경이면 그날 목록) |
| 순서 변경 목록이 그날 항목과 다름 | 409 `order_mismatch` + `current` |
| 하루 50개 초과 | 409 `day_item_limit` |
| `day`가 여행 기간 밖 | 422 `validation_error` |
| **여행 기간을 줄여 밖으로 밀려나는 항목이 있음** (여행 PATCH) | 409 `trip_period_conflict` + `detail`에 날짜별 개수 |
| 검증 실패 (`place_id` 형식 등) | 422 — Google 호출 없음 |
| 호출 제한 초과 | 429 `rate_limited` + `Retry-After` |
| Google 실패·형식 오류 | 502 `upstream_error` |
| 서버에 Places 키 없음 | 503 `places_unavailable` |

## 7. 데이터 변경

마이그레이션 1개: `create_itinerary_items`

**itinerary_items** — 05-data-model.md 4절 그대로, 다음을 정한다:
- `trip_id` FK → trips `ON DELETE CASCADE`
- `created_by`, `updated_by` FK → users `ON DELETE SET NULL`
- UNIQUE `(trip_id, day, position)` **DEFERRABLE INITIALLY DEFERRED**
- CHECK `position >= 0`, `stay_minutes BETWEEN 0 AND 1440`, 좌표는 둘 다 있거나 둘 다 없음 (`location_fetched_at`도 같이)
- enum `travel_mode` (`drive`, `transit`, `walk`)
- 인덱스: `location_fetched_at` (정리 명령용)

## 8. 보안 요구사항

| 위협 | 요구사항 | 확인 방법 (테스트) |
|---|---|---|
| T06 | 새 `{trip_id}` 라우트 모두 권한 확인 (F2 전수 검사에 자동 포함) | `test_all_trip_routes_require_membership`, 케이스 목록에 새 라우트 추가 |
| T06 | 비멤버가 항목 추가·수정·삭제·순서 변경 → 404 | 기존 `test_non_member_gets_404_on_every_trip_route` 확장 |
| T06 | 다른 여행의 항목 ID를 내 여행 경로로 수정·삭제 → 404, 원래 항목 그대로 (S2 규칙) | `test_item_of_other_trip_returns_404` |
| T06 | 순서 변경 목록에 다른 여행 항목을 끼워 넣기 → 409, 아무것도 안 바뀜 | `test_reorder_with_foreign_item_is_rejected` |
| T07 | viewer의 항목 추가·수정·삭제·순서 변경 → 403 | `test_viewer_cannot_modify_items` |
| T08 | 내보낸 멤버가 항목 API 호출 → 404 | `test_removed_member_cannot_touch_items` |
| T29 | 항목 version 불일치 409, 동시 추가 시 position 중복 없음 | `test_update_item_with_stale_version_returns_409`, `test_concurrent_adds_get_distinct_positions` |
| T20 | API 키가 응답·로그에 없음, 헤더로만 전송 | `test_places_key_not_in_response_or_logs`, `test_places_key_sent_in_header_not_url` |
| T23 | 자동완성 분당 60회·하루 1,000회, 상세 하루 300회, 그 외 분당 120회 초과 시 429 | `test_places_rate_limits`, `test_user_rate_limit` |
| T23 | 필드 마스크가 정해진 값 (Pro 필드 없음) | `test_place_details_field_mask_is_essentials_only` |
| T32 | `place_id`·`session_token`에 `../`, `/`, `?` 등 → 422, Google 호출 0회 | `test_malformed_place_id_never_reaches_google` |
| — | Google 응답의 잘못된 좌표·place_id는 버림, Google 에러 본문은 응답에 없음 | `test_invalid_google_response_is_rejected`, `test_google_error_body_not_exposed` |
| — | 앱이 보낸 좌표는 무시 (스키마에 없음 → 422) | `test_client_supplied_location_is_rejected` |
| — | 30일 지난 좌표는 응답에 없고 정리 명령이 지움 | `test_stale_location_hidden`, `test_expire_locations_job` |

Google은 테스트에서 실제로 호출하지 않는다 (respx로 가짜 응답, F1과 같은 방식).

**방어 제거 시험**: (1) `place_id` 형식 검증 제거 → T32 테스트 실패 (2) 항목 조회에서 `trip_id` 조건 제거 → 다른 여행 항목 테스트 실패 (3) 여행 행 잠금 제거 → 동시 추가 테스트 실패 (4) 사용자별 제한 제거 → T23 테스트 실패

## 9. 앱

| 항목 | 내용 |
|---|---|
| 데이터 (`features/itinerary/data`) | 항목 모델(`ItineraryItem`, `TravelMode`), `ItineraryApi` / (`features/places/data`) 장소 모델, `PlacesApi` |
| 스냅샷 | F2의 `TripSnapshot`에 `items` 추가. 일정 탭은 스냅샷의 항목을 날짜별로 나눠 보여준다 |
| S06 일정 (여행 상세의 일정 탭) | 위: 날짜 목록(가로 스크롤, "12/24 (목)" 형식, 오늘 또는 첫날 선택). 아래: 그날 항목. O E: "+ 추가", 길게 눌러 순서 변경, 밀어서 삭제(확인) |
| S08 장소 검색 | 2글자 이상 + 0.3초 멈춤 → 자동완성. 화면에 들어올 때 세션 토큰 생성. 목록 아래 "Google Maps" 출처 표시. 장소 선택 → 장소 상세 호출 후 S09로 |
| S09 항목 추가·수정 | 제목(필수), 장소(S08), 날짜(여행 기간 안에서 선택), 시작 시각, 머무는 시간, 이동수단(차량·대중교통·도보), 메모. 장소를 고르면 "Google 장소 이름: ○○ [이 이름 사용]". viewer는 읽기 전용 |
| S10 장소 정보 (바텀 시트) | 일정 제목, 주소(장소 상세), "Google 지도에서 열기"(외부 브라우저), "Google Maps" 출처 표시 |
| 에러 처리 | F2 공통 처리 + `order_mismatch`·`version_conflict`면 그날 목록 새로고침, `429` "잠시 후 다시 시도해주세요", `502`·`503` "장소 검색을 사용할 수 없습니다" (일정 화면은 정상) |
| 새 패키지 | `url_launcher` (Google 지도 열기). 세션 토큰은 `Random.secure()`로 만들어 새 패키지 없음 |

**Google 출처 표시**: Places 결과를 Google 지도 없이 보여줄 때는 Google Maps 출처 표시가 필요하다. 형식(로고 또는 텍스트)은 구현 전에 Google의 [Places API 정책](https://developers.google.com/maps/documentation/places/web-service/policies)을 확인해서 맞춘다.

## 10. 테스트 계획

- **서버 단위**: 항목 입력 검증, 순서 재배치 계산, Google 응답 파싱·검증, 좌표 메모리 보관(10분 만료), 사용자별 제한기, 정리 명령
- **서버 API** (필수 5종): 6절의 모든 엔드포인트 — 토큰 없음 401, 비멤버 404, 역할 부족 403, 정의되지 않은 필드 422, 정상 응답. 다른 날로 옮기기, 삭제 후 번호 당기기, 여행 기간 축소 409
- **보안**: 8절 전부 (`tests/security/test_itinerary_authz.py`, `tests/security/test_places.py`)
- **앱**: 항목 모델 변환, 날짜별 나누기, 폼 검증, 역할별 버튼, 자동완성 0.3초 대기·2글자 조건, 세션 토큰 형식, 순서 변경 요청 본문
- **수동 확인 (iOS 시뮬레이터, 실제 Places 키)**
  1. 장소 검색 → 항목 추가 → 일정 탭 표시
  2. 길게 눌러 순서 변경, 다른 날로 옮기기, 삭제
  3. 장소 정보 시트 → Google 지도 열기
  4. 여행 기간을 줄여 409 확인
  5. Google Cloud 콘솔에서 호출 수 확인 (자동완성이 세션으로 묶였는지)

## 11. 서버 설정 추가

| 환경변수 | 설명 |
|---|---|
| `GOOGLE_PLACES_API_KEY` | 서버용 Places 키. `.env`에만. 비어 있으면 장소 API만 503 |
| `PLACES_AUTOCOMPLETE_PER_MINUTE` / `PER_DAY` | 기본 60 / 1000 |
| `PLACES_DETAILS_PER_DAY` | 기본 300 |
| `USER_RATE_LIMIT_PER_MINUTE` | 기본 120 |

`.env.example`에 빈 값과 설명 주석을 추가한다. 운영 서버용 키는 따로 만들고 서버 IP로 제한한다 (로컬 키는 집 IP가 바뀔 수 있어 API 제한만 — 위협 모델 T20에 기록).

## 12. 열린 질문

- **S10 장소 정보에 Google 장소 이름을 보여줄지**: 지금 설계는 비용 때문에 사용자가 저장한 제목만 보여준다. 이름이 꼭 필요하면 장소 정보 시트에서만 Pro 필드를 추가할 수 있다 (월 5,000회 무료, 그 뒤 비쌈)
- **좌표 정리 자동 실행**: 운영 배포 때 cron 또는 서버 시작 시 주기 작업 중에서 정한다
- **위치 편향**: 여행 목적지(자유 텍스트)로는 좌표를 알 수 없어서, 그날 첫 장소 좌표를 쓴다. 첫 장소를 고르기 전에는 편향 없이 검색된다

## 13. 구현 결과 (2026-11-10)

**테스트**: 서버 263개(F3 추가 87개, 파라미터별 포함), 앱 71개(F3 추가 16개) 통과. lint·타입 검사 통과.
**실행 확인**: Nginx 경유 curl로 일정 추가·순서·스냅샷·기간 축소 409·키 없을 때 503 확인. 시뮬레이터에서 F3 빌드 실행(여행 목록까지). 일정 탭·장소 검색 화면 조작과 실제 Google 호출은 개발자 확인 대기 (Places 키 필요).

**요금 확인 (공식 페이지, 2026-11-10)**: 5.1 반영. 처음 쓴 "세션으로 끝나면 자동완성 무료"는 틀렸다. Essentials로 끝난 세션은 자동완성 처음 12회가 과금되고 13회째부터 무료. Pro 필드로 끝내면 자동완성은 무료지만 장소 상세가 가장 비싼 Enterprise + Atmosphere로 과금되므로 Essentials가 여전히 싸다.

**방어 제거 시험** (하나씩 끄고 실행 → 되돌림, 커밋하지 않음)

| # | 끈 것 | 실패한 테스트 |
|---|---|---|
| 1 | `place_id` 형식 검증(스키마 + 클라이언트) | Google 호출 차단 3종, 일정의 잘못된 place_id, 잘못된 Google 응답, 자동완성 항목 거르기, 단위 검증 4종 (10개) |
| 2 | 항목 조회의 `trip_id` 조건 | `test_item_of_other_trip_returns_404` |
| 3 | 여행 행 잠금 | `test_concurrent_adds_get_distinct_positions`, `test_concurrent_transfers_keep_single_owner` |
| 4 | 사용자별 제한 (장소 분당·하루, 전체 분당) | `test_places_rate_limits`, `test_places_daily_limit`, `test_user_rate_limit` |

- 시험 1에서 `..%2F` 경로 케이스는 검증을 꺼도 통과했다. `%2F`가 `/`로 풀려 라우트 자체가 맞지 않아(404) Google까지 가지 않기 때문. 나머지 케이스가 검증 제거를 잡는다

**명세와 달라진 점·알아둘 점**
- 장소 정보 시트도 좌표를 포함한 같은 필드 마스크(`id,formattedAddress,location`)를 쓴다. 같은 Essentials 등급이라 비용 차이 없고, 필드 마스크 상수가 하나로 단순해진다
- 일정에 장소를 넣을 때 캐시에 좌표가 없으면(10분 지남) Google 호출이 **여행 행 잠금을 잡은 상태에서** 일어난다 (최대 10초). 보통은 방금 고른 장소라 캐시에 있어 호출이 없다. 사용자가 늘어 문제가 되면 잠금 전에 좌표를 받도록 바꾼다
- 사용자별 분당 제한(120회)은 `get_current_user`에서 건다. 로그인한 모든 요청에 자동 적용
- 앱 일정 입력 화면의 저장 버튼을 화면 아래 고정으로 바꿨다 (폼이 길어 스크롤해야 저장할 수 있었음)
- 시작 시각은 길게 누르면 지워진다 (별도 지우기 버튼 대신)
