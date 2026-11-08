# syntax=docker/dockerfile:1

# 1단계: 의존성 설치 (빌드 도구는 최종 이미지에 남기지 않는다)
FROM python:3.13-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:0.11.2 /uv /bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src ./src
COPY alembic.ini ./
COPY migrations ./migrations
RUN uv sync --frozen --no-dev

# 2단계: 실행 이미지
FROM python:3.13-slim

# root가 아닌 전용 사용자로 실행한다. 앱 파일은 root 소유라 실행 중에 고칠 수 없다.
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app
COPY --from=builder /app /app

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER 10001
EXPOSE 8000

# FORWARDED_ALLOW_IPS(환경변수)로 지정한 Nginx에서 온 X-Forwarded-* 헤더만 믿는다.
CMD ["uvicorn", "travel_copilot.main:create_app", "--factory", \
     "--host", "0.0.0.0", "--port", "8000", \
     "--proxy-headers", "--no-access-log", "--no-server-header"]
