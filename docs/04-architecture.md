# 아키텍처

> 상태: 초안 (2026-11-08) — 승인 대기
> 범위: MVP (M1 일정·동선, M4 협업·오프라인 바우처 지갑, 소셜 로그인)
> 관련 문서: [02-mvp.md](02-mvp.md), [../security/threat-model.md](../security/threat-model.md)

## 1. 구성 요소

```
┌────────────── Flutter 앱 ──────────────┐
│ 화면(UI) ─ 상태(Riverpod) ─ 데이터 계층 │
│                    │                   │
│   로컬 저장소: 토큰(Keychain/Keystore)  │
│               일정 캐시(SQLite/drift)  │
│               바우처 캐시(암호화 파일)  │
└───────┬─────────────────────┬──────────┘
        │ HTTPS (REST/JSON)   │ 지도 타일 (지도 표시용 키)
        ▼                     ▼
     [Nginx] ── TLS 종료      [Google Maps SDK]
        │
        ▼
  [FastAPI 서버] ──> [PostgreSQL]        사용자·여행·일정·초대·메타데이터
        │       ──> [오브젝트 스토리지]   바우처 파일 (암호화)
        │       ──> [Google Places / Routes API]
        └───────> [카카오 / Apple / Google 공개키(JWKS)]   ID 토큰 검증
```

| 구성 요소 | 역할 |
|---|---|
| Flutter 앱 | 화면, 오프라인 캐시, 소셜 로그인 SDK로 ID 토큰 받기 |
| Nginx | TLS 종료, 요청 크기 제한, 1차 요청 횟수 제한 |
| FastAPI 서버 | 모든 비즈니스 로직과 권한 확인, 외부 API 대리 호출 |
| PostgreSQL | 단일 진실 원천(source of truth) |
| 오브젝트 스토리지 | 바우처 파일만 저장. 로컬 도구는 F7에서 결정 (~~MinIO~~ 공식 이미지 배포 중단), 운영은 S3 호환 서비스 |

## 2. 저장소 구조

하나의 저장소에 앱과 서버를 같이 둔다 (모노레포). 1인 개발이라 API 변경과 앱 변경을 한 PR에 묶을 수 있어서 편하다.

```
travel-copilot/
├── app/                   # Flutter 앱
├── server/                # FastAPI 서버
├── infra/
│   ├── docker-compose.yml # 로컬 개발 환경
│   └── nginx/
├── docs/                  # 제품·설계 문서
├── security/              # 보안 문서, 점검 에이전트
└── .github/workflows/     # CI (app, server 각각 + 보안 점검)
```

## 3. 서버 구조

**스택**: Python 3.13, FastAPI, Pydantic v2, SQLAlchemy 2.0 (async) + asyncpg, Alembic, httpx, pytest. 패키지 관리는 uv.

비동기를 쓰는 이유: Google API·JWKS 같은 외부 호출이 많아서, 기다리는 동안 다른 요청을 처리할 수 있어야 한다.

```
server/
├── src/travel_copilot/
│   ├── main.py            # 앱 생성, 라우터 등록, 미들웨어, 전역 예외 핸들러
│   ├── core/              # 설정(환경변수), DB 세션, 토큰·암호화 유틸, 공통 에러
│   ├── auth/              # 소셜 로그인 검증, 토큰 발급·갱신·폐기
│   ├── users/             # 내 정보, 회원 탈퇴
│   ├── trips/             # 여행, 멤버, 권한 확인 의존성
│   ├── itinerary/         # 일정 항목, 순서, 이동 구간
│   ├── places/            # Google Places·Routes 대리 호출, 호출 제한
│   ├── invites/           # 초대 링크
│   └── vouchers/          # 업로드·저장·다운로드
├── migrations/            # Alembic
└── tests/
    ├── unit/
    ├── api/
    └── security/          # 공격 시나리오 회귀 테스트
```

**기능 폴더 하나의 계층**

```
router.py      HTTP 요청·응답만. 권한 의존성을 여기서 건다
schemas.py     Pydantic 요청·응답 모델 (입력값 검증)
service.py     비즈니스 로직. HTTP를 모른다
repository.py  DB 접근. SQLAlchemy 쿼리는 여기에만
models.py      SQLAlchemy 테이블 정의
```

**권한 확인은 의존성으로 강제한다**: 여행에 속한 리소스를 다루는 모든 라우터는 `require_trip_member(role=...)` 의존성을 거친다. 의존성이 빠진 라우터를 잡는 테스트를 둔다 (위협 T06·T07).

## 4. 앱 구조

**스택**: Flutter (stable), Dart 3, Riverpod, go_router, dio, drift, flutter_secure_storage, google_maps_flutter, pdfrx

```
app/lib/
├── main.dart
├── core/
│   ├── api/               # dio 클라이언트, 토큰 자동 첨부·갱신, 에러 변환
│   ├── storage/           # secure storage, drift DB, 암호화 파일 저장소
│   ├── router/            # go_router, 딥링크(초대 링크) 처리
│   └── ui/                # 공통 위젯, 테마
└── features/
    ├── auth/
    ├── trips/
    ├── itinerary/
    ├── invites/
    └── vouchers/
        ├── data/          # API 호출, 로컬 캐시, 저장소(repository)
        ├── state/         # Riverpod provider
        └── ui/            # 화면, 위젯
```

API 클라이언트는 직접 작성한다. 서버가 만드는 OpenAPI 명세로 Dart 코드를 자동 생성하는 방법도 있지만, MVP 규모에서는 생성 도구 설정보다 직접 쓰는 게 단순하다. API가 많아지면 다시 검토한다.

## 5. 통신 규칙

| 항목 | 규칙 |
|---|---|
| 프로토콜 | HTTPS만. 앱에서 평문 HTTP 차단 (iOS ATS, Android 평문 차단 설정) |
| 형식 | REST + JSON, 경로는 `/api/v1/...` |
| 인증 | `Authorization: Bearer <액세스 토큰>`. 쿠키를 쓰지 않으므로 CSRF 대응은 필요 없음 |
| ID | UUID (서버가 생성). 추측을 어렵게 하지만 **권한 확인을 대신하지 않는다** |
| 시간 | UTC, ISO 8601. 일정의 "현지 시각"은 날짜·시각 + 시간대 이름(`Europe/Paris`)으로 따로 저장 |
| 에러 | RFC 9457 형식 (`type`, `title`, `status`, `detail`). 내부 정보·스택 트레이스 미포함 |
| 동시 수정 | 수정 요청에 `version`을 포함, 다르면 `409 Conflict` |
| 목록 | 커서 기반 페이지네이션 |

## 6. 핵심 흐름

### 로그인
1. 앱이 소셜 로그인 SDK로 ID 토큰을 받는다 (nonce 포함)
2. `POST /api/v1/auth/{provider}`로 ID 토큰 전송
3. 서버가 공급자 공개키로 서명·iss·aud·exp·nonce 검증 → `(provider, sub)`로 사용자 찾기 또는 생성
4. 서버가 액세스 토큰(짧게) + 리프레시 토큰 발급 → 앱은 secure storage에 저장
5. 액세스 토큰이 만료되면 앱의 API 클라이언트가 자동으로 갱신 (리프레시 토큰은 매번 교체)

### 일정에 장소 추가
1. 앱이 검색어 입력 → 서버 `GET /places/autocomplete` → 서버가 Google Places 호출 (사용자별 호출 제한)
2. 사용자가 장소 선택 → 서버에 일정 항목 추가 요청 (Google `place_id` 포함)
3. 서버는 `place_id`·좌표·사용자가 입력한 제목만 저장한다 (Google 약관, [05-data-model.md](05-data-model.md) 2절)
4. 하루 일정을 조회할 때 서버가 Google Routes로 이동시간을 계산해 **응답에만 담는다** (저장하지 않음)

### 초대 링크 참여
1. 편집자가 링크 생성 → 서버가 랜덤 토큰 생성, 해시만 저장, 링크 URL 반환
2. 앱이 OS 공유 시트로 전송
3. 받은 사람이 링크를 열면 Universal Link / App Link로 앱이 열림 (앱이 없으면 설치 안내 웹페이지)
4. 로그인 후 서버에 토큰 제출 → 만료·사용 횟수·폐기 여부 확인 → 멤버로 추가

### 바우처 업로드·열람
1. 앱이 파일을 **서버로** 업로드 (스토리지에 직접 올리지 않음 — 서버가 저장 전에 형식·크기를 검증해야 하므로)
2. 서버가 파일 시그니처·크기 확인 → 암호화 → 스토리지에 랜덤 이름으로 저장 → 메타데이터는 DB에
3. 열람 시 서버가 권한 확인 후 파일 전달. 앱은 받은 파일을 기기 키로 암호화해서 캐시
4. 다운로드 방식(서버 경유 vs 짧게 만료되는 직접 URL)과 서버 암호화 방식은 바우처 설계 문서에서 확정

## 7. 오프라인 원칙

- **서버가 단일 진실 원천.** 앱 캐시는 마지막으로 받은 사본이다
- **오프라인에서는 읽기만.** 일정 조회(사용자가 쓴 제목·메모·계획 시각), 바우처 열람. 지도는 SDK 캐시에 의존하며 보장하지 않음
- **수정은 온라인에서만.** 오프라인에서 수정 버튼을 누르면 "연결 후 다시 시도" 안내
- **동기화 시점**: 앱 실행, 화면 당겨서 새로고침, 수정 성공 직후
- **캐시 삭제**: 로그아웃, 탈퇴, 여행에서 내보내졌음을 서버가 알려줄 때 (위협 T08·T18)
- **바우처 미리 받기**: 여행 시작 전에 바우처를 미리 기기에 받아두도록 앱이 안내 (출국 후 받으려다 실패하는 상황 방지)

## 8. 환경

| 환경 | 구성 | 용도 |
|---|---|---|
| local | Docker Compose (서버, PostgreSQL, Nginx + mkcert 인증서. 파일 저장소는 F7에서 추가) | 개발, 공격 실습 |
| staging | 운영과 같은 구성, 별도 키·DB | 출시 전 확인, 점검 도구 실행 |
| production | 5단계(배포·운영 보안)에서 호스팅 결정 | 실서비스 |

설정은 모두 환경변수로 받고 (`.env`, 커밋 금지), 환경마다 키를 따로 쓴다.

## 9. 주요 결정 기록

| # | 결정 | 이유 | 대안 |
|---|---|---|---|
| D1 | 모노레포 | 1인 개발, API·앱 변경을 한 PR로 | 저장소 분리 |
| D2 | 서버 비동기 (async SQLAlchemy) | 외부 API 호출이 많음 | 동기 + 스레드 풀 |
| D3 | Bearer 토큰, 쿠키 미사용 | 모바일 앱 전용, CSRF 고려 불필요 | 쿠키 세션 |
| D4 | Google API는 서버 경유 | 키 보호, 호출 제한, 요금 통제 (T20·T23) | 앱에서 직접 호출 |
| D5 | 바우처 업로드는 서버 경유 | 저장 전 검증 (T15) | 스토리지에 직접 업로드 |
| D6 | 오프라인은 읽기 전용 | 충돌 병합 복잡도 회피 | 오프라인 수정 + 병합 (2차) |
| D7 | API 클라이언트 직접 작성 | MVP 규모에서 더 단순 | OpenAPI 코드 생성 |
| D8 | Google 데이터는 `place_id`·좌표(30일)만 저장, 이름·주소·이동시간은 매번 조회 | Google Maps Platform 약관 | 저장 허용 공급자(Mapbox 영구 지오코딩, OpenStreetMap)로 교체 |

## 10. 열린 질문

- **오프라인 일정 표시 범위**: D8 때문에 오프라인에서는 Google 장소 이름·주소·이동시간이 보이지 않고, 사용자가 쓴 제목·메모·계획 시각만 보인다. 이 수준으로 충분한지 사용 테스트로 확인한다
- 앱이 설치되지 않은 사람이 초대 링크를 열었을 때 보여줄 웹페이지를 어디서 호스팅할지 (딥링크 도메인과 같이 결정)
- 운영 호스팅 (5단계)
