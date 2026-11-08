# Travel Copilot

AI 여행 코파일럿 & 오프라인 바우처 지갑. 기획·설계 문서는 [docs/](docs/), 보안 문서는 [security/](security/)에 있다.

```
app/      Flutter 앱 (iOS·Android)
server/   FastAPI 서버
infra/    로컬 개발 환경 (Docker Compose, Nginx)
docs/     기획·설계·기능 명세
security/ 보안 로드맵, 위협 모델, 점검 기록
```

## 로컬 개발 환경

### 1. 도구 설치

```bash
brew install uv mkcert gitleaks pre-commit
# Flutter (stable), Docker(OrbStack 또는 Docker Desktop), Xcode 별도 설치
# Android 개발 시 Android Studio + Android SDK
```

### 2. 처음 한 번

```bash
# 커밋 전 비밀값·포맷 검사 훅
pre-commit install

# 로컬 HTTPS 인증서. mkcert -install은 내 컴퓨터가 로컬 루트 인증서를 믿게 한다 (비밀번호 입력 필요)
mkcert -install
./infra/scripts/gen-certs.sh

# 환경변수. 복사 후 POSTGRES_PASSWORD를 영문·숫자 무작위 값으로 바꾼다
cp .env.example .env
```

### 3. 서버 실행

```bash
docker compose --env-file .env -f infra/docker-compose.yml up -d --build
curl https://localhost/api/v1/health        # {"status":"ok"}
```

- API 문서 (로컬에서만): https://localhost/api/v1/docs
- 마이그레이션: `docker compose --env-file .env -f infra/docker-compose.yml exec server alembic upgrade head`
- 종료: `docker compose --env-file .env -f infra/docker-compose.yml down` (DB 데이터까지 지우려면 `-v`)

### 4. 서버 테스트

테스트는 Compose의 PostgreSQL에 있는 `travel_copilot_test` DB를 쓴다 (컨테이너 첫 실행 시 자동 생성).

```bash
set -a; . ./.env; set +a
export TEST_DATABASE_URL="postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_HOST_PORT}/travel_copilot_test"
cd server
uv run ruff check . && uv run ruff format --check . && uv run mypy && uv run pytest
```

### 5. 앱 실행

```bash
cd app
flutter pub get
```

**iOS 시뮬레이터** — 시뮬레이터가 로컬 루트 인증서를 믿게 한 뒤 실행:

```bash
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl keychain booted add-root-cert "$(mkcert -CAROOT)/rootCA.pem"
flutter run --dart-define-from-file=env/local.json
```

**Android 에뮬레이터** — 에뮬레이터에서 내 컴퓨터는 `10.0.2.2`다:

1. `$(mkcert -CAROOT)/rootCA.pem`을 에뮬레이터에 끌어다 놓고, 설정 → 보안 → 인증서 설치에서 CA 인증서로 설치
2. `flutter run --dart-define-from-file=env/local.android.json`

디버그 빌드만 사용자 설치 인증서를 믿는다. 릴리스 빌드는 시스템 인증서만 믿는다.

> ⚠️ mkcert 루트 개인키(`$(mkcert -CAROOT)/rootCA-key.pem`)는 절대 복사·공유하지 않는다. 기기에 설치하는 건 공개 인증서 `rootCA.pem`뿐이다.

**코드 생성** — freezed·riverpod·다국어 파일을 바꾼 뒤:

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

생성된 파일(`*.g.dart`, `*.freezed.dart`, `lib/l10n/gen/`)도 커밋한다.

### 6. 앱 검사

```bash
cd app
dart format --set-exit-if-changed . && flutter analyze && flutter test
```

## 개발 방식

[docs/03-dev-process.md](docs/03-dev-process.md)와 [docs/08-conventions.md](docs/08-conventions.md)를 따른다.
