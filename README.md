# Travel Copilot

AI 여행 코파일럿 & 오프라인 바우처 지갑.

```
app/      Flutter 앱 (iOS·Android)
server/   FastAPI 서버
infra/    로컬 개발 환경 (Docker Compose, Nginx)
docs/     기획·설계·기능 명세
security/ 보안 로드맵, 위협 모델, 점검 기록
```

## 시작하기

설정·실행·테스트·동작 확인 방법은 [docs/00-getting-started.md](docs/00-getting-started.md)에 있다.

```bash
# 서버 켜기 (처음 한 번 설정은 위 문서 2절)
docker compose --env-file .env -f infra/docker-compose.yml up -d --build
curl --cacert "$(mkcert -CAROOT)/rootCA.pem" https://localhost/api/v1/health   # {"status":"ok"}

# 앱 실행 (iOS 시뮬레이터)
cd app && flutter run --dart-define-from-file=env/local.json
```

## 문서

| 문서 | 내용 |
|---|---|
| [docs/01-prd.md](docs/01-prd.md) | 기획서 |
| [docs/02-mvp.md](docs/02-mvp.md) | MVP 범위·기술 스택 |
| [docs/03-dev-process.md](docs/03-dev-process.md) | 개발 프로세스 |
| [docs/04-architecture.md](docs/04-architecture.md) ~ [docs/09-tasks.md](docs/09-tasks.md) | 설계 (아키텍처, 데이터 모델, API, 화면, 개발 규칙, 작업 목록) |
| [docs/features/](docs/features/) | 기능 명세 |
| [security/](security/) | 보안 로드맵, 위협 모델, 점검 기록 |
