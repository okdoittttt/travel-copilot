# 실행 가이드

> 로컬에서 Travel Copilot을 설정하고, 실행하고, 동작을 확인하는 방법.
> 기준: F1(Google 로그인) 구현 시점 (2026-11-08). 기능이 추가될 때마다 이 문서를 갱신한다.

## 1. 구성 한눈에 보기

```
[Flutter 앱] ──HTTPS──> [Nginx :443] ──HTTP(Docker 내부망)──> [FastAPI 서버 :8000] ──> [PostgreSQL]
                         TLS 종료                               에러 형식 통일          개발 DB + 테스트 DB
                         보안 헤더                               요청 로그
                         요청 ID 부여                            인증 (Google ID 토큰 검증)
                                                                      │
[Google 로그인 SDK] ── ID 토큰 ──> 앱 ──> 서버                         └──> Google 공개키(JWKS)
```

| 폴더 | 내용 |
|---|---|
| `server/` | FastAPI 서버 (Python 3.13, uv) |
| `app/` | Flutter 앱 (iOS·Android, 번들 ID `com.okdoittttt.travelcopilot`) |
| `infra/` | Docker Compose, Nginx 설정, 인증서 스크립트 |
| `.github/` | CI 워크플로, PR 템플릿, Dependabot |

현재 있는 API: `GET /health`, 인증 `POST /auth/nonce` · `/auth/google/login` · `/auth/refresh` · `/auth/logout`, 내 정보 `GET·PATCH /me` (모두 `/api/v1` 아래).

## 2. 처음 한 번 설정

### 2.1 도구

```bash
brew install uv mkcert gitleaks pre-commit osv-scanner
```

별도 설치: Flutter (stable), Docker (OrbStack 또는 Docker Desktop), Xcode, Android 개발 시 Android Studio + Android SDK

### 2.2 저장소 설정 (저장소 루트에서)

```bash
# 1) 커밋할 때 비밀값·코드 형식 검사
pre-commit install

# 2) 내 컴퓨터가 로컬 루트 인증서를 믿게 함 (브라우저·curl용, 비밀번호 입력 필요)
mkcert -install

# 3) 로컬 HTTPS 인증서 생성 → infra/nginx/certs/ (git 제외)
./infra/scripts/gen-certs.sh

# 4) 환경변수 파일. POSTGRES_PASSWORD를 영문·숫자 무작위 값으로 바꾼다
cp .env.example .env
```

| `.env` 항목 | 설명 |
|---|---|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | DB 계정. 비밀번호는 URL에 들어가므로 영문·숫자만 |
| `POSTGRES_HOST_PORT` | 내 컴퓨터에서 DB에 접속할 포트. 기본 55432 (다른 프로젝트의 5432와 충돌 방지) |
| `LOG_LEVEL` | 서버 로그 레벨 |
| `JWT_SECRET` | 자체 액세스 토큰 서명 키. 32자 이상 무작위: `openssl rand -base64 48` |
| `GOOGLE_WEB_CLIENT_ID` | Google 웹 클라이언트 ID (ID 토큰의 aud). 공개값 |
| `GOOGLE_ALLOWED_AZP` | 쉼표로 구분한 Google iOS·Android 클라이언트 ID (ID 토큰의 azp 검사). 공개값 |

앱 설정은 `app/env/local.json`(iOS 시뮬레이터)·`app/env/local.android.json`(Android 에뮬레이터)에 있다. 공개값만 들어가므로 커밋한다.

| `app/env/*.json` 항목 | 설명 |
|---|---|
| `API_BASE_URL` | 서버 주소 (HTTPS만) |
| `GOOGLE_SERVER_CLIENT_ID` | Google 웹 클라이언트 ID. 앱이 이 값으로 ID 토큰을 요청한다 |
| `GOOGLE_IOS_CLIENT_ID` | Google iOS 클라이언트 ID. **iOS에서 Google 로그인하려면 필요** (Android는 비워둠) |

iOS Google 로그인은 `app/ios/Runner/Info.plist`의 URL scheme에 iOS 클라이언트 ID를 뒤집은 값(`com.googleusercontent.apps.<번호>-<문자열>`)도 등록돼 있어야 한다.

> ⚠️ `.env`, `infra/nginx/certs/`, mkcert 루트 개인키(`$(mkcert -CAROOT)/rootCA-key.pem`)는 절대 커밋·공유하지 않는다. 기기에 설치하는 건 공개 인증서 `rootCA.pem`뿐이다.

## 3. 매일 실행

모든 명령은 저장소 루트 기준.

### 3.1 서버

```bash
# 켜기 (코드 바뀌었으면 --build가 다시 빌드)
docker compose --env-file .env -f infra/docker-compose.yml up -d --build

# 상태 / 로그 / 끄기
docker compose --env-file .env -f infra/docker-compose.yml ps
docker compose --env-file .env -f infra/docker-compose.yml logs -f server
docker compose --env-file .env -f infra/docker-compose.yml down        # DB 데이터까지 지우려면 -v

# DB 마이그레이션 적용
docker compose --env-file .env -f infra/docker-compose.yml exec server alembic upgrade head
```

- API 문서 (로컬에서만 열림): https://localhost/api/v1/docs
- DB 접속 (DB 도구용): `localhost:55432`, 계정은 `.env`

### 3.2 앱 — iOS 시뮬레이터

```bash
cd app
flutter pub get
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl keychain booted add-root-cert "$(mkcert -CAROOT)/rootCA.pem"   # 시뮬레이터마다 한 번
flutter run --dart-define-from-file=env/local.json
```

### 3.3 앱 — Android 에뮬레이터

에뮬레이터에서 내 컴퓨터 주소는 `10.0.2.2`다.

1. `$(mkcert -CAROOT)/rootCA.pem`을 에뮬레이터 창에 끌어다 놓기
2. 에뮬레이터 설정 → 보안 → 인증서 설치 → CA 인증서로 설치
3. 실행:
   ```bash
   cd app
   flutter run --dart-define-from-file=env/local.android.json
   ```

디버그 빌드만 사용자가 설치한 인증서를 믿는다. 릴리스 빌드는 시스템 인증서만 믿는다.

### 3.4 앱 코드 생성

freezed 모델, Riverpod provider, 화면 문구(`lib/l10n/app_ko.arb`)를 바꾼 뒤:

```bash
cd app
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

생성된 파일(`*.g.dart`, `*.freezed.dart`, `lib/l10n/gen/`)도 커밋한다. CI가 커밋 누락을 검사한다.

## 4. 검사·테스트

### 4.1 서버

테스트는 Compose의 PostgreSQL 안에 있는 `travel_copilot_test` DB를 쓴다 (서버 스택이 켜져 있어야 함). 테스트 시작 시 이 DB를 비우고 마이그레이션을 적용하므로 개발 DB에는 영향이 없다. Google은 실제로 호출하지 않고 테스트가 만든 가짜 공개키로 대신한다.

```bash
set -a; . ./.env; set +a
export TEST_DATABASE_URL="postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_HOST_PORT}/travel_copilot_test"

cd server
uv run ruff check .          # lint
uv run ruff format --check . # 포맷
uv run mypy                  # 타입 검사
uv run pytest                # 테스트
```

| 테스트 폴더 | 내용 |
|---|---|
| `tests/unit/` | 설정, 로그 형식, 요청 횟수 제한, Google 공개키 캐시 |
| `tests/api/` | `/health`, 404·405 에러 형식, 요청 ID, 로그인·내 정보 API |
| `tests/security/` | 500·422 응답에 내부 정보·입력값 없음, 문서 노출 범위, 비밀번호 미출력, 로그에 토큰 미기록, Google ID 토큰 위조·다른 앱용·알고리즘 바꿔치기·nonce 재사용, 리프레시 토큰 재사용 감지, 요청 횟수 제한 |

### 4.2 앱

```bash
cd app
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

### 4.3 보안 검사 (CI와 같은 명령)

```bash
gitleaks git --no-banner --redact --config .gitleaks.toml           # git 이력 비밀값

cd server
uv export --frozen --no-hashes --no-emit-project --format requirements.txt > /tmp/req.txt
uvx pip-audit --strict --requirement /tmp/req.txt                   # Python 의존성 취약점
cd ..

osv-scanner scan --lockfile=server/uv.lock --lockfile=app/pubspec.lock   # Python·Dart 의존성 취약점
```

## 5. 동작 확인 체크리스트

서버 스택을 켠 상태에서 저장소 루트에서 실행한다.

```bash
CA="$(mkcert -CAROOT)/rootCA.pem"
C="docker compose --env-file .env -f infra/docker-compose.yml"
```

> zsh에서는 `$C`처럼 변수에 담은 명령이 나뉘지 않으니, 아래 `$C` 자리에는 명령을 그대로 쓴다.

| # | 확인할 것 | 명령 | 기대 결과 |
|---|---|---|---|
| 1 | 서버 응답 | `curl --cacert "$CA" https://localhost/api/v1/health` | `{"status":"ok"}` |
| 2 | HTTP → HTTPS | `curl -I http://localhost/api/v1/health` | `301`, `Location: https://...` |
| 3 | 에러 형식 | `curl --cacert "$CA" https://localhost/api/v1/nope` | `{"type":"about:blank",...,"code":"not_found",...}` |
| 4 | 보안 헤더 | `curl --cacert "$CA" -I https://localhost/api/v1/health` | `x-content-type-options: nosniff`, `referrer-policy: no-referrer`, `cache-control: no-store` |
| 5 | 옛 TLS 거절 | `curl --cacert "$CA" --tlsv1.1 --tls-max 1.1 https://localhost/api/v1/health` | 연결 실패 (protocol version) |
| 6 | 로그에 토큰 없음 | `curl --cacert "$CA" -s "https://localhost/api/v1/health?token=MY_SECRET"` 후 `$C logs server \| tail -3` | `"path": "/api/v1/health"`만 있고 `MY_SECRET` 없음 |
| 7 | 서버 비root | `$C exec server id` | `uid=10001(app)` |
| 8 | DB 외부 차단 | `docker port travel-copilot-postgres-1` | `127.0.0.1:55432`만 |
| 9 | 서버 직접 접근 불가 | `docker port travel-copilot-server-1` | 출력 없음 |
| 10 | 비밀값 커밋 차단 | `echo 'aws_access_key_id = AKIAQX7RZ4M2P9LK3TWE' > leak.txt && git add leak.txt && git commit -m test` | `gitleaks ... Failed`, 커밋 안 됨. 확인 후 `git reset leak.txt && rm leak.txt` |
| 11 | 첫 실행 | iOS 시뮬레이터에서 앱 실행 (저장된 로그인 없음) | 로그인 화면 ("Google로 계속하기") |
| 12 | API 문서 범위 | 브라우저로 https://localhost/api/v1/docs | 로컬에서는 열림 (staging·production은 서버 테스트로 404 확인) |
| 13 | nonce 발급 | `curl --cacert "$CA" -X POST https://localhost/api/v1/auth/nonce` | `{"nonce":"...43자...","expires_in":300}` |
| 14 | 가짜 ID 토큰 거절 | `curl --cacert "$CA" -X POST https://localhost/api/v1/auth/google/login -H 'content-type: application/json' -d '{"id_token":"aaa.bbb.ccc"}'` | `401`, `"code":"id_token_invalid"`, 실패 이유는 응답에 없음 (서버 로그에만 `reason`) |
| 15 | 토큰 없는 요청 | `curl --cacert "$CA" -i https://localhost/api/v1/me` | `401`, `www-authenticate: Bearer`, `"code":"token_missing"` |
| 16 | Google 로그인 | 앱에서 "Google로 계속하기" → 계정 선택 | 홈에 "○○님, 로그인되었습니다" (iOS 클라이언트 ID 필요) |
| 17 | 로그인 유지 | 앱을 완전히 종료 후 다시 실행 | 로그인 화면 없이 바로 홈 |
| 18 | 로그아웃 | 홈의 로그아웃 → DB에서 `SELECT revoked_at FROM refresh_tokens;` | 로그인 화면으로 이동, `revoked_at`에 시각 기록 |
| 19 | 리프레시 토큰 재사용 감지 | 같은 리프레시 토큰으로 `POST /auth/refresh`를 두 번 | 두 번째 `401`, 그 로그인의 토큰 전부 `revoked_at` 기록, 서버 로그에 "리프레시 토큰 재사용 감지" |

## 6. 자주 겪는 문제

| 증상 | 원인 | 해결 |
|---|---|---|
| `Bind for 0.0.0.0:5432 failed: port is already allocated` | 다른 프로젝트가 포트 사용 | `.env`의 `POSTGRES_HOST_PORT`를 다른 값으로 |
| `80`/`443` 포트 충돌 | 다른 웹 서버 실행 중 | 해당 프로세스 종료 (`lsof -nP -iTCP:443 -sTCP:LISTEN`) |
| curl `SSL certificate problem` | 로컬 인증서를 믿지 않음 | `--cacert "$(mkcert -CAROOT)/rootCA.pem"` 붙이거나 `mkcert -install` |
| 앱이 "연결 실패" (서버는 정상) | 시뮬레이터·에뮬레이터에 루트 인증서 미설치 | 3.2·3.3의 인증서 설치 단계 |
| 앱 시작 시 `API_BASE_URL이 없거나 HTTPS가 아닙니다` | `--dart-define-from-file` 빠짐 | `flutter run --dart-define-from-file=env/local.json` |
| pytest가 `TEST_DATABASE_URL 환경변수가 필요합니다`로 실패 | 환경변수 미설정 | 4.1의 `export` 두 줄 실행 |
| 테스트 DB가 없다는 에러 | DB 볼륨이 테스트 DB 생성 스크립트 추가 전에 만들어짐 | `$C down -v` 후 다시 `up` (개발 DB 데이터도 지워짐) |
| CI `생성 파일이 커밋되지 않았습니다` | 코드 생성 결과 미커밋 | 3.4 실행 후 생성 파일 커밋 |
| 서버가 `JWT_SECRET` 관련 에러로 시작 안 됨 | `.env`에 값이 없거나 32자 미만 | `openssl rand -base64 48`로 만들어 `.env`에 추가 |
| 앱 시작 시 `GOOGLE_SERVER_CLIENT_ID가 없습니다` | `env/*.json`에 값 없음 | 웹 클라이언트 ID 입력 |
| iOS에서 Google 로그인 버튼을 누르면 앱이 종료되거나 설정 오류 | iOS 클라이언트 ID·URL scheme 미설정 | `env/local.json`의 `GOOGLE_IOS_CLIENT_ID`와 `Info.plist` URL scheme 확인 |
| 로그인 시 `nonce_invalid` | nonce 5분 만료, 또는 같은 로그인 재시도 | 다시 로그인 (앱이 새 nonce를 받음) |
| 커밋이 `gitleaks Failed`로 막힘 | 비밀값으로 보이는 문자열 포함 | 실제 비밀값이면 제거하고 `.env`로. 가짜 값이면 `.gitleaks.toml` 허용 목록 검토 |

## 7. 아직 안 된 것

| 항목 | 시점 |
|---|---|
| Android 에뮬레이터 실행 확인 (F0·F1) | 늦어도 F5 전에 Android Studio 설치 후 |
| 카카오·Apple 로그인 | F10 |
| 파일 저장소(S3 호환) | F7 (MinIO 공식 이미지 배포 중단, 대체 도구는 F7 명세에서 결정) |
| 스테이징 서버 | 출시 준비 전 (외부 준비물 P6) |
| Nginx ↔ 서버 구간 패킷 캡처 | 보안 로드맵 0단계 학습 과제 |
