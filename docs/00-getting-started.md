# 실행 가이드

> 로컬에서 Travel Copilot을 설정하고, 실행하고, 동작을 확인하는 방법.
> 기준: F6(동기화·오프라인 일정) 구현 시점 (2026-11-15). 기능이 추가될 때마다 이 문서를 갱신한다.

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
# 앱 지도 키 (선택, 없으면 지도 탭만 안내 문구). git 제외 파일이다
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig   # 열어서 GOOGLE_MAPS_IOS_KEY = 키값
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
| 16 | Google 로그인 | 앱에서 "Google로 계속하기" → 계정 선택 | "내 여행" 목록 화면 (iOS 클라이언트 ID 필요) |
| 17 | 로그인 유지 | 앱을 완전히 종료 후 다시 실행 | 로그인 화면 없이 바로 "내 여행" |
| 18 | 로그아웃 | "내 여행" 오른쪽 위 로그아웃 → DB에서 `SELECT revoked_at FROM refresh_tokens;` | 로그인 화면으로 이동, `revoked_at`에 시각 기록 |
| 19 | 리프레시 토큰 재사용 감지 | 같은 리프레시 토큰으로 `POST /auth/refresh`를 두 번 | 두 번째 `401`, 그 로그인의 토큰 전부 `revoked_at` 기록, 서버 로그에 "리프레시 토큰 재사용 감지" |
| 20 | 여행 만들기 | 앱에서 "여행 만들기" → 제목·목적지·기간·시간대 입력 → 저장 | 여행 상세 화면, 내 역할 "소유자". 뒤로 가면 목록의 "다가오는 여행"에 표시 |
| 21 | 입력 검사 | 빈 칸으로 저장, 기간 61일 이상 선택 | 항목마다 안내 문구, 서버 요청 없음 |
| 22 | 여행 수정 | 상세 메뉴 → 여행 수정 → 제목 변경 → 저장 | 상세·목록에 새 제목 |
| 23 | 동시 수정 (409) | 수정 화면을 열어 둔 채, 아래 5.1의 curl로 같은 여행 제목을 먼저 바꾼 뒤 앱에서 저장 | "다른 멤버가 먼저 수정했습니다" + 최신 내용. [내 수정 다시 적용]이면 내 값으로 저장, [취소]면 최신 내용 유지 |
| 24 | 멤버 관리 | 아래 5.1로 가짜 멤버 추가 → 상세의 멤버 탭 당겨서 새로고침 → 멤버 메뉴 | 역할 변경·내보내기(확인 대화상자)·소유권 넘기기 동작 |
| 25 | 소유권 넘긴 뒤 | 가짜 멤버에게 소유권 넘기기 | 내 역할 "편집자", 메뉴에 "여행 삭제" 없음·"여행 나가기" 있음. 나가면 목록에서 사라짐 |
| 26 | 여행 삭제 | 소유자로 메뉴 → 여행 삭제 → 제목 다시 입력 | 제목이 같아야 삭제 버튼 활성화, 삭제 후 목록으로 |
| 27 | 남의 여행 접근 | `curl --cacert "$CA" -H "Authorization: Bearer $TOKEN" https://localhost/api/v1/trips/$(uuidgen)` | `404`, `"code":"not_found"` (멤버가 아닌 여행도 같은 응답) |
| 28 | 일정 추가 (장소 없이) | 여행 상세 → 일정 탭 → 날짜 고르기 → "일정 추가" → 제목만 입력 → 저장 | 그날 목록 맨 아래에 표시. Places 키가 없어도 된다 |
| 29 | 장소 검색 | 일정 추가 → "장소 선택" → 2글자 이상 입력 | 0.3초 뒤 결과, 아래에 "Google Maps" 표시. **`.env`에 `GOOGLE_PLACES_API_KEY` 필요** (없으면 "장소 검색을 사용할 수 없습니다") |
| 30 | Google 이름 힌트 | 검색 결과에서 장소 선택 | 입력 화면에 "Google 장소 이름: ○○ [이 이름 사용]". 누르면 제목에 채움 |
| 31 | 장소 정보 | 장소가 있는 일정 오른쪽 📍 → 시트 | 주소, "Google 지도에서 열기", "Google Maps" 표시 |
| 32 | 순서 변경·삭제 | 일정을 길게 눌러 끌기 / 왼쪽으로 밀기 → 삭제 확인 | 새 순서 유지(새로고침해도), 삭제 후 번호 당김 |
| 33 | 다른 날로 옮기기 | 일정 누르기 → 날짜 변경 → 저장 | 새 날 맨 뒤로 이동 |
| 34 | 여행 기간 축소 | 마지막 날에 일정을 둔 채 여행 수정으로 종료일을 하루 당기기 | "기간 밖으로 밀려나는 일정이 있습니다 (12/27 1개)…" 안내, 저장 안 됨 |
| 35 | viewer | 앱에서 가짜 멤버에게 소유권 넘기기 → 5.1의 "내 역할을 viewer로" SQL → 일정 탭 당겨서 새로고침 | 추가 버튼·끌기·밀기 없음, 일정을 누르면 읽기 전용 |
| 36 | Google 호출 수 | Google Cloud 콘솔 → Places API (New) → 측정항목 | 검색 한 번에 자동완성 몇 회 + 장소 상세 1회 |
| 37 | 이동 구간 | 장소 있는 일정 3개, 둘째·셋째에 이동수단(도보·대중교통) 선택 → 일정 탭 | 항목 사이에 "21분 · 3.9km" 같은 줄. **서버 키에 Routes API 허용 필요** (없으면 "이동시간을 알 수 없어요") |
| 38 | 이동수단 미선택·장소 없음 | 이동수단을 비운 항목, 장소 없는 항목 | "이동수단을 선택하세요", "— 장소 없음" |
| 39 | 늦음 경고 | 첫 일정 10:00·머무는 시간 2시간, 다음 일정 시작을 12:00으로 | 구간 줄이 주황색 "⚠ N분 늦음" |
| 40 | 지도 | [지도] 전환 | 번호 마커, 처음에 모든 마커가 보이게. 마커 누르면 장소 정보 시트. **지도 키 필요** (없으면 "지도를 사용할 수 없습니다") |
| 41 | 이동시간 저장 안 함 | 같은 날을 두 번 열기 → Google Cloud 콘솔 Routes 측정항목 | 열 때마다 구간 수만큼 호출 (캐시 없음, 약관) |
| 42 | 초대 링크 만들기 | owner로 여행 → 멤버 탭 → [초대 링크] → [새 링크] → 편집자 선택 | 편집자 경고 문구. [만들기] → 공유 시트가 열림 ([복사]로 링크 복사). 화면 목록에는 링크 주소가 없음 |
| 43 | 링크로 참여 | 다른 계정으로 로그인(5.1 "두 번째 계정") → 여행 목록 오른쪽 위 사람+ 아이콘 → 링크 붙여넣기 → [다음] | "OOO님이 '여행'(기간)에 보기 전용 멤버로 초대했습니다" → [참여] → 여행 상세, 여행 목록에 보임 |
| 44 | 같은 링크 다시 | 참여한 계정으로 같은 링크를 다시 붙여넣기 | 확인 없이 바로 여행 상세 (사용 횟수 안 늘어남) |
| 45 | 폐기된 링크 | owner가 [폐기] → 다른 계정이 그 링크 붙여넣기 | "더 이상 쓸 수 없는 초대 링크입니다…" |
| 46 | 다른 사이트 링크 | `https://evil.example.com/invite#...` 붙여넣기 | "초대 링크 형식이 아닙니다" (서버 요청 없음) |
| 47 | 내보낼 때 링크 폐기 | 열린 링크가 있는 상태에서 멤버 내보내기 | 대화상자에 "열린 초대 링크도 모두 폐기 (N개)" 체크됨. 내보낸 뒤 목록의 링크가 "폐기됨" |
| 48 | 안내 웹페이지(W01) | 브라우저로 `https://localhost/invite` | 설치 안내 페이지. 개발자 도구 응답 헤더에 `Content-Security-Policy` |
| 49 | 앱 링크 확인 파일 | `curl --cacert "$CA" https://localhost/.well-known/apple-app-site-association` (assetlinks.json도) | JSON, `content-type: application/json`. 팀 ID·인증서 지문은 아직 자리 표시 값 (P1·P4 후 교체) |
| 50 | 캐시 저장 | 온라인에서 여행 목록을 열고, 여행 두 개를 각각 열어 본다 | 평소와 같음 (뒤에서 기기 DB에 저장됨) |
| 51 | 오프라인 시작 | `$C stop nginx` (또는 Mac Wi-Fi 끄기) → 앱을 완전히 종료(`q`) 후 다시 `flutter run` | 로그인 화면 없이 "내 여행"이 저장된 목록으로 보이고, 위에 "오프라인 · 마지막 동기화: N분 전" 배너 |
| 52 | 오프라인 일정 | 50에서 연 여행 → 일정 탭 | 제목·시각·메모가 보이고, 이동 구간 자리에 "오프라인 — 이동시간은 연결 후 표시됩니다", [지도]는 "지도는 연결 후 볼 수 있습니다" |
| 53 | 오프라인 수정 차단 | [여행 만들기], [일정 추가], 메뉴의 여행 수정, 멤버 탭 [초대 링크] | "연결 후 수정할 수 있습니다." 안내, 화면 이동·요청 없음 |
| 54 | 다시 연결 | `$C start nginx` → 배너의 [다시 시도] (또는 홈으로 나갔다가 앱으로 돌아오기) | 배너가 사라지고 최신 내용 |
| 55 | 내보내진 여행 정리 (T08) | 두 번째 계정을 여행에 넣은 뒤(43) 그 계정으로 여행을 한 번 연다 → 첫 계정이 내보내기 → 두 번째 계정에서 목록 당겨서 새로고침 → 다시 51처럼 오프라인으로 | 여행이 목록에서 사라지고, 오프라인에서도 보이지 않음 |
| 56 | 계정 전환 정리 (T34) | 계정 A로 여행을 본 뒤 로그아웃 → 계정 B로 로그인 → 51처럼 오프라인 | A의 여행이 보이지 않음 |

### 5.1 수동 확인 도우미 (로컬 전용)

**Places 키 넣기 (#29~31)**: 저장소 루트 `.env`(`.env.example` 아님)에 `GOOGLE_PLACES_API_KEY=키값`을 추가하고 서버를 다시 띄운다 (`docker compose ... up -d`). 키는 Google Cloud에서 "Places API (New)"만 허용하도록 제한한 서버용 키여야 한다.

**오래된 좌표 정리 (Google 약관 30일)**: 서버가 떠 있는 동안 6시간마다 자동으로 지운다 (F4). 바로 지우려면 `docker compose --env-file .env -f infra/docker-compose.yml exec server python -m travel_copilot.jobs.expire_locations` → "좌표를 지운 항목: N".

**두 번째 계정으로 참여 확인 (#43~47)**: 시뮬레이터에서 [로그아웃] → 다른 Google 계정으로 로그인하면 된다. 링크는 #42의 공유 시트에서 [복사]한 것을 붙여넣는다 (같은 시뮬레이터라 클립보드가 남아 있다). 계정이 하나뿐이면 아래 curl로 가짜 사용자가 참여하게 할 수 있다.

**링크를 눌러 앱이 바로 열리는 것**은 아직 확인할 수 없다. Apple Developer 계정(P1)과 공인 도메인(P4)이 있어야 Apple·Google이 확인 파일을 가져갈 수 있기 때문이다 (features/invites.md 12절). 지금은 붙여넣기 경로로 확인한다.

**지도 키 넣기 (#40)**: `app/ios/Flutter/Secrets.xcconfig`에 `GOOGLE_MAPS_IOS_KEY = 키값` (git 제외 파일, 저장소가 공개라서). 키는 Google Cloud에서 "iOS 앱" + 번들 ID `com.okdoittttt.travelcopilot`, API는 "Maps SDK for iOS"만 허용. 넣은 뒤 앱을 다시 빌드(`flutter run`)해야 반영된다.


두 번째 사용자가 필요한 확인(멤버 관리, 초대 참여)은 SQL로 가짜 사용자를 만들어도 된다. **로컬 개발 DB에서만** 쓴다.

```bash
set -a; . ./.env; set +a
PSQL="docker compose --env-file .env -f infra/docker-compose.yml exec -T postgres psql -U $POSTGRES_USER -d ${POSTGRES_DB:-travel_copilot}"

# 가짜 사용자를 만들어 내가 가장 최근에 만든 여행에 편집자로 넣기
$PSQL -c "
WITH u AS (INSERT INTO users (id, display_name, created_at, updated_at)
           VALUES (gen_random_uuid(), '가짜 친구', now(), now()) RETURNING id),
     t AS (SELECT id FROM trips ORDER BY created_at DESC LIMIT 1)
INSERT INTO trip_members (trip_id, user_id, role) SELECT t.id, u.id, 'editor' FROM t, u;"

# 내 역할을 viewer로 (#35, 가짜 멤버에게 소유권을 넘긴 뒤. 가장 최근 여행 기준)
$PSQL -c "UPDATE trip_members SET role = 'viewer'
WHERE user_id = (SELECT id FROM users ORDER BY created_at LIMIT 1)
  AND trip_id = (SELECT id FROM trips ORDER BY created_at DESC LIMIT 1) AND role = 'editor';"

# curl용 액세스 토큰 (내 계정, 15분). 409 확인 등에 쓴다
MY_ID=$($PSQL -tAc "SELECT id FROM users ORDER BY created_at LIMIT 1")
TOKEN=$(cd server && uv run python -c "import sys,uuid; from travel_copilot.auth.access_token import create_access_token as c; print(c(uuid.UUID(sys.argv[1]), sys.argv[2], 900))" "$MY_ID" "$JWT_SECRET")

# 가짜 사용자가 초대 링크로 참여 (#43 대체). LINK는 #42에서 복사한 링크
FAKE_ID=$($PSQL -tAc "INSERT INTO users (id, display_name, created_at, updated_at) VALUES (gen_random_uuid(), '초대받은 친구', now(), now()) RETURNING id" | head -1)
FAKE_TOKEN=$(cd server && uv run python -c "import sys,uuid; from travel_copilot.auth.access_token import create_access_token as c; print(c(uuid.UUID(sys.argv[1]), sys.argv[2], 900))" "$FAKE_ID" "$JWT_SECRET")
INVITE="${LINK#*#}"   # 링크의 # 뒤만. 토큰은 본문으로만 보낸다
curl --cacert "$CA" -X POST -H "Authorization: Bearer $FAKE_TOKEN" -H 'content-type: application/json' \
  -d "{\"token\": \"$INVITE\"}" https://localhost/api/v1/invites/accept

# 여행 제목 먼저 바꾸기 (#23). TRIP_ID와 VERSION은 GET /trips 응답에서
curl --cacert "$CA" -X PATCH -H "Authorization: Bearer $TOKEN" -H 'content-type: application/json' \
  -d '{"version": VERSION, "title": "다른 사람이 바꾼 제목"}' https://localhost/api/v1/trips/TRIP_ID
```

## 6. 자주 겪는 문제

| 증상 | 원인 | 해결 |
|---|---|---|
| `Bind for 0.0.0.0:5432 failed: port is already allocated` | 다른 프로젝트가 포트 사용 | `.env`의 `POSTGRES_HOST_PORT`를 다른 값으로 |
| `80`/`443` 포트 충돌 | 다른 웹 서버 실행 중 | 해당 프로세스 종료 (`lsof -nP -iTCP:443 -sTCP:LISTEN`) |
| 앱 시작 시 `INVITE_BASE_URL이 없거나 HTTPS가 아닙니다` | `env/*.json`에 값 없음 (F5에서 추가) | `"INVITE_BASE_URL": "https://localhost"` (서버의 `INVITE_BASE_URL`과 같게) |
| `nginx.conf`를 고쳤는데 반영 안 됨 / `nginx -t`가 파일 없음 | 편집기가 파일을 새로 만들어 단일 파일 마운트가 옛 파일을 가리킴 | `docker compose --env-file .env -f infra/docker-compose.yml up -d --force-recreate nginx` |
| curl `SSL certificate problem` | 로컬 인증서를 믿지 않음 | `--cacert "$(mkcert -CAROOT)/rootCA.pem"` 붙이거나 `mkcert -install` |
| 앱이 "연결 실패" (서버는 정상) | 시뮬레이터·에뮬레이터에 루트 인증서 미설치 | 3.2·3.3의 인증서 설치 단계 |
| 앱 시작 시 `API_BASE_URL이 없거나 HTTPS가 아닙니다` | `--dart-define-from-file` 빠짐 | `flutter run --dart-define-from-file=env/local.json` |
| pytest가 `TEST_DATABASE_URL 환경변수가 필요합니다`로 실패 | 환경변수 미설정 | 4.1의 `export` 두 줄 실행 |
| 테스트 DB가 없다는 에러 | DB 볼륨이 테스트 DB 생성 스크립트 추가 전에 만들어짐 | `$C down -v` 후 다시 `up` (개발 DB 데이터도 지워짐) |
| 오프라인 배너가 계속 남아 있음 | 마지막 요청이 서버에 닿지 못했다 (앱은 OS 연결 상태가 아니라 실제 요청 결과로 판단) | 서버·nginx가 켜져 있는지 확인 후 배너의 [다시 시도] |
| 기기 캐시를 비우고 처음부터 확인하고 싶음 | 캐시는 로그아웃 때 지워진다 | 앱에서 로그아웃, 또는 시뮬레이터에서 앱 삭제 |
| CI `생성 파일이 커밋되지 않았습니다` | 코드 생성 결과 미커밋 | 3.4 실행 후 생성 파일 커밋 |
| 서버가 `JWT_SECRET` 관련 에러로 시작 안 됨 | `.env`에 값이 없거나 32자 미만 | `openssl rand -base64 48`로 만들어 `.env`에 추가 |
| 앱 시작 시 `GOOGLE_SERVER_CLIENT_ID가 없습니다` | `env/*.json`에 값 없음 | 웹 클라이언트 ID 입력 |
| iOS에서 Google 로그인 버튼을 누르면 앱이 종료되거나 설정 오류 | iOS 클라이언트 ID·URL scheme 미설정 | `env/local.json`의 `GOOGLE_IOS_CLIENT_ID`와 `Info.plist` URL scheme 확인 |
| 로그인 시 `nonce_invalid` | nonce 5분 만료, 또는 같은 로그인 재시도 | 다시 로그인 (앱이 새 nonce를 받음) |
| 커밋이 `gitleaks Failed`로 막힘 | 비밀값으로 보이는 문자열 포함 | 실제 비밀값이면 제거하고 `.env`로. 가짜 값이면 `.gitleaks.toml` 허용 목록 검토 |

## 7. 아직 안 된 것

| 항목 | 시점 |
|---|---|
| Android 에뮬레이터 실행 확인 (F1~F6, 백업 제외 포함) | Android Studio 설치 후 한 번에 (features/invites.md 12절) |
| 실기기 비행기 모드 확인 | P1(실기기 설치) 후. 시뮬레이터에는 비행기 모드가 없어 nginx 중지로 대신한다 |
| 링크를 눌러 앱 열기 (Universal Links·App Links) | P1(Apple Developer)·P4(도메인)·스테이징 준비 후 |
| 카카오·Apple 로그인 | F10 |
| 파일 저장소(S3 호환) | F7 (MinIO 공식 이미지 배포 중단, 대체 도구는 F7 명세에서 결정) |
| 스테이징 서버 | 출시 준비 전 (외부 준비물 P6) |
| Android 지도 키 | Android 확인 때 |
| 실시간 교통 반영 이동시간, 경로선 | 2차 검토 |
| Nginx ↔ 서버 구간 패킷 캡처 | 보안 로드맵 0단계 학습 과제 |
