# 개발 규칙

> 상태: 초안 (2026-11-08) — 승인 대기
> 목적: Claude가 일관된 코드를 쓰고, security/ 에이전트가 같은 기준으로 점검하기 위한 약속
> 관련 문서: [03-dev-process.md](03-dev-process.md), [04-architecture.md](04-architecture.md), [06-api.md](06-api.md)

## 1. 공통

- **언어**: 코드 식별자(변수·함수·클래스·파일 이름)는 영어. 주석·문서·화면 문구·커밋 메시지 내용은 한국어
- **주석**: "무엇을"이 아니라 "왜"를 쓴다. 코드만 봐서 알 수 있는 내용은 쓰지 않는다
- **포맷**: 사람이 고민하지 않는다. 포맷 도구 결과가 정답
- **파일 크기**: 한 파일 한 역할. 300줄을 넘으면 나눌지 검토
- **TODO**: `TODO(이유):` 형식, 방치하지 않는다. 미룬 작업은 tasks 문서나 이슈로 옮긴다
- **비밀값**: 코드·테스트·문서 어디에도 실제 키를 쓰지 않는다. 예시는 `.env.example`에 가짜 값으로

## 2. 서버 (Python / FastAPI)

### 2.1 도구

| 도구 | 용도 | 설정 |
|---|---|---|
| uv | 패키지·가상환경, `uv.lock` 커밋 | |
| ruff | lint + 포맷 | 규칙: `E, F, W, I, N, UP, B, S(bandit), ASYNC, SIM, RUF, D(docstring)`, 줄 길이 100, `pydocstyle.convention = "google"` |
| mypy | 타입 검사 | `strict = true` |
| pytest | 테스트 | pytest-asyncio, httpx, respx |

### 2.2 이름

| 대상 | 규칙 | 예 |
|---|---|---|
| 모듈·함수·변수 | snake_case | `create_trip`, `trip_id` |
| 클래스 | PascalCase | `TripService`, `TripCreate` |
| 상수 | UPPER_SNAKE | `MAX_TRIP_DAYS` |
| Pydantic 스키마 | `<대상><동작>` | `TripCreate`, `TripUpdate`, `TripRead` |
| 도메인 예외 | `<대상><상황>` | `TripNotFound`, `VersionConflict` |
| DB 테이블 | 복수형 snake_case | `trips`, `trip_members` |

### 2.3 계층 규칙

```
router.py      → service.py      → repository.py   → DB
(HTTP, 권한)     (비즈니스 로직)     (SQL)
```

| 계층 | 할 수 있는 것 | 하면 안 되는 것 |
|---|---|---|
| router | 요청 파싱, 권한 의존성, 서비스 호출, 응답 변환 | DB 세션 직접 사용, 비즈니스 로직 |
| service | 규칙 판단, 여러 repository 조합, 트랜잭션 경계, 외부 API 호출 | `Request`·`HTTPException` 등 HTTP 객체 사용 |
| repository | SQLAlchemy 쿼리 | 권한 판단, 다른 기능 폴더의 repository 호출 |

- 기능 폴더 사이의 호출은 **service → 다른 기능의 service**로만
- DB 모델(SQLAlchemy)을 API 응답으로 그대로 내보내지 않는다. 항상 Pydantic 스키마로 변환 (컬럼이 실수로 새는 것 방지)

### 2.4 코드 작성

- **전부 async.** 동기 블로킹 호출(`requests`, `time.sleep`, 동기 파일 I/O) 금지. 불가피하면 `run_in_threadpool`
- **설정**은 `core/config.py`의 pydantic-settings 객체로만. 코드 안에서 `os.environ` 직접 읽기 금지
- **에러**: service는 도메인 예외를 던지고, `main.py`의 전역 핸들러가 RFC 9457 형식으로 변환. 라우터에서 `HTTPException` 직접 사용 금지
- **트랜잭션**: 요청 하나 = 트랜잭션 하나가 기본. 커밋은 service에서 명시적으로
- **시간**: `datetime.now(UTC)`만. naive datetime 금지
- **타입**: 공개 함수는 인자·반환 타입 필수. `Any`는 이유 주석과 함께만

### 2.5 Docstring (Google 스타일)

- **대상**: 모든 공개 모듈·클래스·함수 (`_`로 시작하지 않는 것). 테스트 함수와 마이그레이션 파일은 제외
- **형식**: Google 스타일. 첫 줄은 한 문장 요약, 필요하면 빈 줄 뒤에 설명, 그다음 섹션
- **섹션**: `Args:`, `Returns:`, `Raises:` (해당될 때만). 타입은 타입 힌트에 있으므로 docstring에 다시 쓰지 않는다
- **언어**: 한국어. 식별자는 그대로
- **ruff `D` 규칙**으로 누락·형식을 검사한다

```python
async def accept_invite(self, token: str, user_id: UUID) -> Trip:
    """초대 토큰으로 여행에 참여한다.

    사용 횟수는 조건부 UPDATE로 원자적으로 늘려서, 동시 요청으로
    max_uses를 넘기지 못하게 한다.

    Args:
        token: 초대 링크의 토큰 원문. 해시로 바꿔서 조회한다.
        user_id: 참여하는 사용자 ID.

    Returns:
        참여한 여행.

    Raises:
        InviteNotFound: 토큰에 해당하는 초대가 없을 때.
        InviteExpired: 만료·폐기·사용 횟수 소진일 때.
        AlreadyMember: 이미 멤버일 때.
    """
```

- **라우터 함수 주의**: FastAPI는 엔드포인트 함수의 docstring을 OpenAPI 문서의 설명으로 그대로 노출한다. 라우터 docstring에는 API 사용자에게 보여도 되는 내용만 쓰고, 내부 구현·보안 처리 방식은 service의 docstring에 쓴다
- **"왜" 주석과의 관계**: docstring은 함수의 약속(무엇을 받고, 돌려주고, 언제 실패하는지), 코드 안 주석은 구현의 이유

### 2.6 마이그레이션 (Alembic)

- 모델을 바꾸면 같은 PR에 마이그레이션 포함
- 자동 생성 후 **반드시 내용을 읽고 고친다** (자동 생성은 인덱스·enum 변경을 놓치는 경우가 많음)
- main에 머지된 마이그레이션 파일은 수정하지 않는다. 고칠 게 있으면 새 마이그레이션
- 파일 이름: `YYYYMMDD_HHMM_<설명>.py`

### 2.7 로깅

- 표준 `logging` + JSON 형식, 요청마다 `request_id`
- 로그 레벨: 정상 흐름 `INFO`, 거절된 요청(401·403·404·409·429) `INFO`, 외부 API 실패 `WARNING`, 예상 못 한 예외 `ERROR`
- **로그에 남기지 않는 것**: 액세스·리프레시 토큰, ID 토큰, 초대 토큰, nonce, 바우처 파일 내용·원래 파일 이름, 이메일, 요청 본문 전체 (T25)
- 사용자는 `user_id`(UUID)로만 기록

## 3. 앱 (Flutter)

### 3.1 도구

| 도구 | 용도 |
|---|---|
| `dart format` | 포맷 (줄 길이 100) |
| very_good_analysis | lint 규칙 |
| freezed + json_serializable | 불변 데이터 모델, JSON 변환 (코드 생성) |
| riverpod_generator | provider 코드 생성 |
| build_runner | 코드 생성 실행. **생성 파일(`*.g.dart`, `*.freezed.dart`)은 커밋한다** (CI·리뷰에서 바로 보이게) |
| flutter_test, mocktail | 테스트 |

### 3.2 이름

| 대상 | 규칙 | 예 |
|---|---|---|
| 파일 | snake_case | `trip_detail_screen.dart` |
| 클래스·위젯 | PascalCase | `TripDetailScreen` |
| 변수·함수 | camelCase | `tripId`, `loadTrip()` |
| 화면 위젯 | `<이름>Screen` | `TripListScreen` |
| provider | `<대상>Provider` (생성기 규칙) | `tripDetailProvider` |
| repository | `<대상>Repository` | `TripRepository` |

### 3.3 계층 규칙

```
ui (위젯)  →  state (Riverpod provider)  →  data (repository → API 클라이언트 / 로컬 DB)
```

- 위젯에서 dio·drift·secure storage를 직접 부르지 않는다
- repository가 "캐시 먼저, 온라인이면 갱신" 규칙을 담당한다 (07-screens 5절)
- 기능 폴더 사이에는 `data/`의 공개 repository로만 접근

### 3.4 코드 작성

- **에러**: API 에러는 `core/api`에서 앱 공통 예외(`sealed class AppException`)로 변환. 화면은 이 타입만 분기
- **문자열**: 화면 문구는 `lib/l10n/*.arb`에만. 위젯 안에 한국어 문자열 직접 쓰기 금지
- **로그**: `print`, `debugPrint` 금지 (lint로 차단). 앱 로거만 사용하고 릴리스 빌드에서는 경고 이상만, 토큰·개인정보는 디버그에서도 금지 (T21)
- **비밀값 저장**: 토큰·암호화 키는 `core/storage`의 secure storage 래퍼로만. `SharedPreferences`에 민감 정보 금지
- **파일 저장**: 바우처는 `core/storage`의 암호화 파일 저장소로만. 평문으로 디스크에 쓰지 않는다 (임시 파일 포함)
- **딥링크**: 받은 URL은 `core/router`에서 도메인·경로를 검증한 뒤에만 처리
- **async**: `BuildContext`를 await 뒤에 쓸 때 `mounted` 확인

## 4. 테스트

### 4.1 서버

| 종류 | 위치 | 내용 |
|---|---|---|
| 단위 | `tests/unit/` | service 로직, 유틸 (토큰, 파일 시그니처 판별 등) |
| API | `tests/api/` | 엔드포인트별 정상·실패 흐름 |
| 보안 | `tests/security/` | 공격 시나리오 (IDOR, 권한 상승, 토큰 재사용, 초대 링크 동시 사용 등) |

- **테스트 DB는 실제 PostgreSQL** (Docker). SQLite로 대신하지 않는다
- 테스트마다 트랜잭션 롤백 또는 DB 초기화로 서로 영향 없게
- **외부 API는 실제 호출 금지.** Google·OIDC는 respx로 가짜 응답. OIDC 테스트용 키 쌍은 테스트 안에서 생성
- 테스트 이름: `test_<대상>_<조건>_<결과>` (예: `test_update_item_as_viewer_returns_403`)

**API마다 필수 테스트**

| # | 테스트 | 기대 |
|---|---|---|
| 1 | 토큰 없이 요청 | 401 |
| 2 | 비멤버가 요청 | 404 |
| 3 | 역할이 부족한 멤버가 요청 (해당될 때) | 403 |
| 4 | 정의되지 않은 필드 포함 | 422 |
| 5 | 정상 요청 | 성공 + 응답 형식 |

- 권한 확인 의존성이 빠진 라우터를 찾는 테스트: 앱의 모든 라우트를 훑어서 `/trips/{trip_id}/...` 경로에 `require_trip_member`가 걸려 있는지 확인

### 4.2 앱

| 종류 | 대상 |
|---|---|
| 단위 | repository (캐시·갱신 규칙), 에러 변환, 암호화 저장소 |
| 위젯 | 핵심 화면: 일정 하루(S06), 바우처 보기(S13), 초대 참여(S16), 공통 에러·오프라인 표시 |
| 통합 | MVP 후반에 로그인 → 여행 → 바우처 흐름 1개 |

- 커버리지 % 목표는 두지 않는다. 위의 필수 테스트 목록으로 관리

## 5. 보안 코딩 규칙

security/ 에이전트가 점검할 때 기준으로 쓰는 목록. 위반하면 리뷰에서 반려한다.

| # | 규칙 | 관련 위협 |
|---|---|---|
| S1 | `/trips/{trip_id}/...` 라우터는 `require_trip_member(role=...)` 의존성 필수 | T06·T07 |
| S2 | 리소스 조회는 항상 `trip_id`와 같이 조건을 건다 (`WHERE id = :id AND trip_id = :trip_id`) — ID만으로 조회 금지 | T06 |
| S3 | 요청 스키마는 `extra="forbid"`, 문자열은 길이 상한 필수 | T27 |
| S4 | 문자열을 이어 붙인 SQL 금지. `text()`를 쓸 때는 바인딩 파라미터만 | T27 |
| S5 | 외부 HTTP 호출은 타임아웃 필수 (기본 연결 3초, 전체 10초) | — |
| S6 | 토큰·nonce 생성은 `secrets` 모듈만 (`random` 금지) | T10 |
| S7 | 해시·토큰 비교는 `hmac.compare_digest` | T03·T10 |
| S8 | 토큰·초대 토큰은 해시로만 저장 | T03·T14 |
| S9 | 비밀값은 환경변수로만, 기본값에 실제 키 금지 | T24 |
| S10 | 로그 금지 항목 준수 (2.7절) | T21·T25 |
| S11 | 업로드 파일은 시그니처로 형식 판별, 클라이언트가 준 `Content-Type`·파일 이름 무시 | T15 |
| S12 | 에러 응답에 스택 트레이스·SQL·내부 경로 금지 | T26 |
| S13 | 비멤버·남의 `private` 바우처는 404 (403 아님) | T06·T09 |
| S14 | 새 의존성 추가 시 PR 본문에 이유 기록, 유지보수 상태 확인 | T28 |

## 6. git · PR

### 6.1 브랜치

| 접두어 | 용도 | 예 |
|---|---|---|
| `feat/` | 기능 | `feat/auth-social-login` |
| `fix/` | 버그 수정 | `fix/invite-race-condition` |
| `docs/` | 문서만 | `docs/design` |
| `chore/` | 설정·도구·의존성 | `chore/ci-setup` |
| `refactor/` | 동작 변경 없는 구조 개선 | `refactor/trip-service` |

### 6.2 커밋 메시지

Conventional Commits, 접두어는 영어, 내용은 한국어:

```
feat(trips): 여행 스냅샷 조회 API 추가

- 멤버·일정·바우처 목록을 한 번에 반환
- 비멤버는 404
```

- 접두어: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`, `security`
- 범위(괄호): `auth`, `trips`, `itinerary`, `places`, `invites`, `vouchers`, `app`, `server`, `infra`
- 커밋 하나 = 의미 있는 변경 하나. "WIP" 커밋은 squash 머지로 정리

### 6.3 PR

- PR 하나 = 기능 하나. 리뷰하기 어려울 만큼 크면 나눈다 (기준: 변경 1,000줄, 생성 파일 제외)
- 본문 템플릿 (`.github/pull_request_template.md`, 기반 작업 때 생성):

```markdown
## 요약
## 관련 문서
- 명세: docs/features/...
- 관련 위협: T06, T07
## 변경 내용
## 테스트
- [ ] 서버 테스트 통과
- [ ] 앱 테스트 통과
- [ ] 로컬에서 실행해 확인한 시나리오:
## 보안 점검
- 기록: security/reviews/...
- 미해결 항목과 사유:
## 스크린샷 (화면 변경 시)
```

- 머지: squash 머지, 머지 후 브랜치 삭제

## 7. CI (GitHub Actions)

| 워크플로 | 실행 조건 | 내용 |
|---|---|---|
| `server.yml` | `server/**` 변경 | ruff, mypy, pytest (PostgreSQL 서비스 컨테이너) |
| `app.yml` | `app/**` 변경 | `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` |
| `security.yml` | 모든 PR | gitleaks, pip-audit, osv-scanner. 이후 Semgrep·Trivy 추가 (로드맵 4단계) |

- 모든 워크플로 통과가 머지 조건
- GitHub Actions는 버전 태그가 아니라 커밋 SHA로 고정 (공급망 공격 대응, T28)
- 워크플로 권한은 최소로: `permissions: contents: read` 기본

## 8. 문서

- docs/ 파일은 작성 순서대로 두 자리 번호 (`09-tasks.md` 다음은 `10-...`)
- 기능 명세는 `docs/features/<기능>.md`, 템플릿은 [features/_template.md](features/_template.md)
- 구현이 명세와 달라지면 명세를 먼저 고친다
- 결정을 바꿀 때는 지우지 않고 이유와 같이 남긴다 (예: ~~이전 결정~~ → 새 결정, 이유)

## 9. 완료 기준

[03-dev-process.md](03-dev-process.md) 6절을 따른다.
