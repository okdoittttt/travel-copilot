# F0. 기반

> 상태: 초안 (2026-11-08) — 승인 대기
> 브랜치: `chore/foundation`
> 관련 문서: [../04-architecture.md](../04-architecture.md), [../08-conventions.md](../08-conventions.md), [../09-tasks.md](../09-tasks.md)
> 관련 위협: T21, T22, T24, T25, T26, T28

## 1. 목적

기능 코드를 쓰기 전에, 모든 기능이 올라설 서버·앱·인프라·CI 뼈대를 만든다. 이 작업이 끝나면 "로컬에서 HTTPS로 서버를 띄우고, 앱이 그 서버를 호출하고, PR마다 CI가 검사하는" 상태가 된다.

## 2. 사용자 시나리오

이 작업의 사용자는 개발자(나)다.

1. 저장소를 받고 README의 순서대로 도구 설치, 인증서 생성, `.env` 작성
2. `docker compose up`으로 PostgreSQL·서버·Nginx 실행
3. `https://localhost/api/v1/health` 호출 → `{"status": "ok"}`
4. iOS 시뮬레이터·Android 에뮬레이터에서 앱 실행 → 첫 화면에 서버 상태 "정상" 표시
5. 브랜치에서 커밋하면 pre-commit이 비밀값·포맷 검사, PR을 올리면 CI가 lint·테스트·보안 검사

## 3. 완료 조건

- [ ] `docker compose up` 한 번으로 3개 서비스(Nginx·서버·PostgreSQL)가 정상 실행
- [ ] HTTPS(mkcert 인증서)로 `/api/v1/health` 응답, HTTP 요청은 HTTPS로 리다이렉트
- [ ] 서버: ruff, mypy(strict), pytest 통과
- [ ] 앱: `dart format`, `flutter analyze`, `flutter test` 통과
- [ ] iOS 시뮬레이터, Android 에뮬레이터에서 앱이 서버 `/health` 호출 성공
- [ ] pre-commit 훅이 비밀값이 든 커밋을 막음 (가짜 키로 확인)
- [ ] GitHub Actions 3종(server, app, security)이 PR에서 통과
- [ ] README에 로컬 개발 환경 설정 순서 정리

## 4. 범위 밖

| 항목 | 이유 / 시점 |
|---|---|
| DB 테이블 | 기능별로 추가 (F1부터) |
| 인증, 요청 횟수 제한 | F1 |
| 파일 저장소(S3 호환) | F7. ~~MinIO 컨테이너만 실행~~ → MinIO 공식 이미지 배포 중단으로 F0에서 제외, 대체 도구는 F7 명세에서 결정 |
| 스테이징·운영 배포 | R, 로드맵 5단계 |
| Semgrep, Trivy, ZAP | 로드맵 4단계에서 CI에 추가 |
| 실기기(폰) 연결 | 실기기에 로컬 인증서를 설치해야 해서 번거로움. 필요해지면 그때 |
| 앱 환경별 번들 ID 분리 (dev/prod 앱 동시 설치) | 출시 준비(R) 때 |

## 5. API

| 메서드 | 경로 | 권한 | 변경 사항 |
|---|---|---|---|
| GET | `/api/v1/health` | 🌐 | 신규 |

```json
// 200
{ "status": "ok" }

// 503 (DB 연결 실패)
{ "type": "about:blank", "title": "Service Unavailable", "status": 503, "code": "unavailable", "detail": "일시적으로 서비스를 이용할 수 없습니다." }
```

- 버전·호스트 이름·DB 정보 등 내부 정보는 응답에 넣지 않는다
- OpenAPI 문서(`/docs`, `/openapi.json`)는 `ENV=local`에서만 켜고, staging·production에서는 끈다 (공격자에게 API 지도를 주지 않기 위해)

## 6. 구성 상세

### 6.1 저장소 구조

```
travel-copilot/
├── server/
│   ├── pyproject.toml, uv.lock, Dockerfile, alembic.ini
│   ├── src/travel_copilot/
│   │   ├── main.py
│   │   ├── core/ (config.py, db.py, errors.py, logging.py, middleware.py)
│   │   └── health/ (router.py)
│   ├── migrations/
│   └── tests/ (unit/, api/, security/, conftest.py)
├── app/
│   ├── pubspec.yaml, analysis_options.yaml, l10n.yaml
│   ├── env/ (local.json, local.android.json)
│   └── lib/
│       ├── main.dart, app.dart
│       ├── core/ (api/, config/, logging/, router/, ui/)
│       ├── features/health/ (data/, state/, ui/)
│       └── l10n/app_ko.arb
├── infra/
│   ├── docker-compose.yml
│   ├── nginx/ (nginx.conf, certs/ ← git 제외)
│   └── scripts/gen-certs.sh
├── .github/ (workflows/, pull_request_template.md)
├── .pre-commit-config.yaml, .gitleaks.toml
├── .env.example
└── README.md
```

### 6.2 서버

| 항목 | 내용 |
|---|---|
| 런타임 | Python 3.13 (uv가 설치), FastAPI, uvicorn |
| 설정 (`core/config.py`) | pydantic-settings. 필수 값이 없으면 **시작 시 바로 실패**. 비밀값은 `SecretStr`로 감싸 로그·repr에 안 찍히게 |
| 설정 항목 | `ENV`(local/staging/production), `DATABASE_URL`, `LOG_LEVEL` (저장소 설정은 F7에서 추가) |
| DB (`core/db.py`) | SQLAlchemy async 엔진 + asyncpg, 요청마다 세션을 주는 의존성 |
| 에러 (`core/errors.py`) | 전역 핸들러 3종: 도메인 예외 → 해당 상태, 검증 실패 → 422, 그 외 → 500. 모두 RFC 9457 + `code` |
| 422 응답 | 어느 필드가 왜 틀렸는지만. **입력값을 응답에 다시 담지 않는다** (Pydantic 기본 에러는 입력값을 포함하므로 걸러냄 — 토큰 등이 되돌아가는 것 방지) |
| 500 응답 | 고정 메시지. 스택 트레이스는 서버 로그에만 (T26) |
| 요청 ID | Nginx가 만든 `X-Request-ID`를 받아 로그에 기록, 응답 헤더로 돌려줌. 앱이 보낸 값은 Nginx가 덮어써서 믿지 않음 |
| 로깅 (`core/logging.py`) | JSON 한 줄 로그: 시각, 레벨, request_id, 메서드, 경로, 상태, 소요 시간. 요청 본문·쿼리 문자열·헤더는 기록하지 않음 (T25) |
| 프록시 | uvicorn `--proxy-headers --forwarded-allow-ips`를 Nginx 컨테이너로만 한정 (앱이 IP를 속이지 못하게, 요청 횟수 제한의 기반) |
| CORS | 설정하지 않음 (모바일 앱 전용, 브라우저 요청 불필요) |
| Alembic | async 템플릿으로 초기화. 테이블은 아직 없음 |
| Dockerfile | 다단계 빌드, `python:3.13-slim`, `uv sync --frozen --no-dev`, **root가 아닌 사용자로 실행** |

### 6.3 인프라 (Docker Compose)

| 서비스 | 이미지 | 외부 노출 | 비고 |
|---|---|---|---|
| nginx | `nginx` (버전 고정) | 80, 443 | TLS 종료, 80 → 443 리다이렉트 |
| server | 로컬 빌드 | 없음 (Nginx만 접근) | |
| postgres | `postgres:17-alpine` | `127.0.0.1:55432` (로컬 개발 도구·테스트용, `POSTGRES_HOST_PORT`로 변경 가능 — 다른 프로젝트의 5432와 충돌 방지) | 데이터는 볼륨에, 비밀번호는 `.env` |
| ~~minio~~ | — | — | **제외**: MinIO 공식 Docker 이미지를 더 이상 받을 수 없음 (2026-11 확인). F7에서 대체 도구 결정 |

- 외부 노출 포트는 **`127.0.0.1`로만** 묶는다 (같은 Wi-Fi의 다른 기기가 DB에 붙지 못하게)
- 이미지 태그는 버전까지 고정. 해시(digest) 고정은 로드맵 4단계(Trivy)에서

**Nginx 설정**

| 항목 | 값 |
|---|---|
| TLS | TLS 1.2·1.3만, mkcert 인증서 |
| `server_tokens` | off (Nginx 버전 숨김) |
| 요청 크기 | 기본 1MB (바우처 업로드 경로는 F7에서 별도 설정) |
| 응답 헤더 | `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store` |
| HSTS | 로컬에서는 끔 (localhost에 걸리면 다른 개발 작업에 영향). staging·production에서 켬 |
| 요청 ID | `$request_id`를 `X-Request-ID`로 서버에 전달 (앱이 보낸 값은 덮어씀) |

**Nginx ↔ 서버 구간**은 Docker 내부 네트워크에서 평문 HTTP다. 로드맵 0단계 과제로 캡처해서 확인하고, 운영에서 어떤 조건이면 문제가 되는지 `security/notes/tls.md`에 정리한다.

**인증서 (`infra/scripts/gen-certs.sh`)**
- mkcert로 `localhost`, `127.0.0.1`, `10.0.2.2`(Android 에뮬레이터에서 본 호스트 주소)용 인증서 생성
- `infra/nginx/certs/`에 저장, git 제외
- mkcert 루트 인증서의 **개인키(`rootCA-key.pem`)는 절대 저장소·기기에 복사하지 않는다** — 이게 새면 내 컴퓨터가 믿는 아무 인증서나 만들 수 있다

### 6.4 앱

| 항목 | 내용 |
|---|---|
| 프로젝트 | `flutter create --platforms ios,android --org com.okdoittttt --project-name travelcopilot` → 번들 ID `com.okdoittttt.travelcopilot` |
| 패키지 | flutter_riverpod, riverpod_annotation, go_router, dio, freezed_annotation, json_annotation, logging |
| 개발 패키지 | build_runner, freezed, json_serializable, riverpod_generator, very_good_analysis, mocktail |
| 설정 | API 주소는 `--dart-define-from-file=env/local.json`. 앱에는 비밀값이 없으므로 env 파일은 커밋 (주소만 들어 있음) |
| API 클라이언트 (`core/api`) | dio, 타임아웃(연결 5초, 응답 15초), 에러를 `AppException`으로 변환하는 뼈대 |
| 로거 (`core/logging`) | `logging` 패키지 래퍼. 릴리스 빌드에서는 WARNING 이상만, 콘솔 출력 없음 |
| 라우터 (`core/router`) | go_router, 첫 화면 하나 (`/`) |
| l10n | `app_ko.arb`, 위젯에 문자열 직접 쓰지 않음 |
| 첫 화면 | 개발 확인용: 서버 `/health` 결과("정상" / "연결 실패") 표시. F1에서 시작 화면으로 교체 |

**HTTPS 전용 설정**
- iOS: ATS 기본값 유지 (`NSAllowsArbitraryLoads` 추가 금지)
- Android: `android:usesCleartextTraffic="false"`, `network_security_config.xml`로 평문 차단

**로컬 인증서 신뢰 (개발용, 디버그 빌드만)**
- iOS 시뮬레이터: `xcrun simctl keychain booted add-root-cert <mkcert 루트 인증서>` (README에 명령어)
- Android 에뮬레이터: 루트 인증서를 에뮬레이터에 설치하고, `network_security_config`의 `<debug-overrides>`에서만 사용자 인증서를 신뢰
- **릴리스 빌드는 시스템 인증서만 신뢰한다.** 디버그 설정이 릴리스에 섞이지 않는지 CI 대신 명세 체크리스트로 확인

### 6.5 저장소 도구·CI

**pre-commit (`.pre-commit-config.yaml`)**
- gitleaks (비밀값), ruff (서버), 파일 끝 줄바꿈·공백 정리, 큰 파일(1MB 초과) 커밋 차단

**GitHub Actions**

| 워크플로 | 조건 | 단계 |
|---|---|---|
| `server.yml` | `server/**` 변경 | uv 설치 → `ruff check` → `ruff format --check` → `mypy` → `pytest` (PostgreSQL 서비스 컨테이너) |
| `app.yml` | `app/**` 변경 | Flutter 설치 → `pub get` → `build_runner build` 후 **변경 없음 확인** (생성 파일 커밋 누락 방지) → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test` |
| `security.yml` | 모든 PR, main push | gitleaks (전체 이력), pip-audit (`uv.lock` 기준), osv-scanner (`uv.lock`, `pubspec.lock`) |

- 모든 액션은 **커밋 SHA로 고정**, 옆에 버전 주석 (`# v4.2.0`)
- `permissions: contents: read` 기본, 필요한 작업만 추가
- 같은 브랜치의 이전 실행은 취소 (`concurrency`)
- Dependabot으로 액션·의존성 업데이트 PR 자동 생성 (주 1회)

**그 외**
- `.github/pull_request_template.md` (08-conventions 6.3절)
- `.gitignore`: Flutter·Python 산출물, `infra/nginx/certs/`, `.env`

## 7. 보안 요구사항

| 위협 | 요구사항 | 확인 방법 |
|---|---|---|
| T24 | 비밀값은 `.env`로만, `.env.example`은 가짜 값. pre-commit·CI에서 gitleaks | 가짜 AWS 키를 커밋 시도 → 차단되는지 |
| T24 | 설정의 비밀값은 `SecretStr`, 기본값 없음 | `test_settings_secret_not_in_repr` |
| T26 | 500 응답에 스택 트레이스·내부 정보 없음 | `test_unhandled_error_returns_generic_500` |
| T26 | 422 응답에 입력값이 되돌아가지 않음 | `test_validation_error_does_not_echo_input` |
| T26 | staging·production에서 OpenAPI 문서 비활성 | `test_docs_disabled_outside_local` |
| T25 | 요청 로그에 본문·쿼리·헤더 없음 | `test_request_log_excludes_query_and_headers` |
| T21 | 앱 `print` 금지(lint), 릴리스 빌드 콘솔 로그 없음 | `flutter analyze`, 로거 단위 테스트 |
| T22 | 로컬도 HTTPS, 앱 평문 차단, 릴리스는 시스템 인증서만 | HTTP 요청이 리다이렉트되는지, 앱 설정 파일 검토 |
| T28 | 잠금 파일 커밋, 의존성 취약점 검사, 액션 SHA 고정 | CI `security.yml` |
| — | DB 포트는 127.0.0.1에만 노출 | 다른 기기에서 접속 시도 → 실패 |
| — | 서버 컨테이너 root 미사용 | `docker compose exec server id` |

## 8. 테스트 계획

- **서버 단위**: 설정 검증(필수 값 누락 시 실패, `SecretStr`), 에러 변환 3종, 요청 ID 전달, 로그 형식·제외 항목
- **서버 API**: `/health` 정상 200, DB 끊김 503 / 문서 경로 환경별 동작 / 알 수 없는 경로 404 형식
- **보안**: 위 7절 테스트를 `tests/security/`에
- **앱**: health repository 단위 테스트(dio mock), 첫 화면 위젯 테스트(정상·실패 표시), 로거 릴리스 동작
- **수동 확인**
  1. `docker compose up` → `curl https://localhost/api/v1/health`
  2. `curl -I http://localhost/api/v1/health` → 301
  3. iOS 시뮬레이터·Android 에뮬레이터에서 첫 화면 "정상"
  4. 가짜 키 커밋 시도 → pre-commit 차단
  5. `docker compose exec server id` → root 아님
  6. Nginx ↔ 서버 구간 패킷 캡처 (로드맵 0단계)

## 9. 열린 질문

- ~~번들 ID~~ → **확정: `com.okdoittttt.travelcopilot`** (iOS 번들 ID, Android 패키지 이름 공통). Apple·카카오·Google 등록에 이 값을 쓴다
- 앱 표시 이름: "Travel Copilot" (한국어 이름을 따로 둘지)
