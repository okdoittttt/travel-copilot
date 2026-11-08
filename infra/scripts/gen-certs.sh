#!/bin/sh
# 로컬 HTTPS용 인증서를 만든다.
#
# - localhost, 127.0.0.1, ::1: 내 컴퓨터와 iOS 시뮬레이터
# - 10.0.2.2: Android 에뮬레이터에서 본 내 컴퓨터 주소
#
# 루트 인증서 개인키(rootCA-key.pem)는 mkcert 폴더에만 두고 절대 복사하지 않는다.
# 이 키가 새면 내 컴퓨터가 믿는 아무 인증서나 만들 수 있다.
set -eu

if ! command -v mkcert >/dev/null 2>&1; then
    echo "mkcert가 필요합니다: brew install mkcert" >&2
    exit 1
fi

CERT_DIR="$(cd "$(dirname "$0")/../nginx/certs" && pwd)"

mkcert \
    -cert-file "$CERT_DIR/local.pem" \
    -key-file "$CERT_DIR/local-key.pem" \
    localhost 127.0.0.1 ::1 10.0.2.2

chmod 600 "$CERT_DIR/local-key.pem"

echo
echo "인증서 생성 완료: $CERT_DIR"
echo "시뮬레이터·에뮬레이터에 설치할 루트 인증서(공개용): $(mkcert -CAROOT)/rootCA.pem"
