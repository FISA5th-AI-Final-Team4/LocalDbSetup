#!/bin/sh
set -e

echo "🔧 pg_bigm 확장 설치 시작..."

# root로 패키지 설치
apk add --no-cache git make gcc musl-dev postgresql-dev clang llvm

# clang 심볼릭 링크 생성
ln -sf /usr/bin/clang /usr/bin/clang-19
mkdir -p /usr/lib/llvm19/bin
ln -sf /usr/bin/llvm-lto /usr/lib/llvm19/bin/llvm-lto

# pg_bigm 다운로드 및 빌드
cd /tmp
git clone https://github.com/pgbigm/pg_bigm.git
cd pg_bigm
make USE_PGXS=1
make USE_PGXS=1 install

# 정리
cd /
rm -rf /tmp/pg_bigm

echo "✅ pg_bigm 설치 완료!"
