#!/bin/sh
# 컨테이너를 처음 만들 때 한 번 실행된다. 서버 테스트용 DB를 따로 만든다.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE travel_copilot_test OWNER "$POSTGRES_USER";
EOSQL
