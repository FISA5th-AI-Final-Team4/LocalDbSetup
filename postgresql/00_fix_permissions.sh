#!/bin/sh
set -e

echo "🔒 PostgreSQL 데이터 디렉토리 권한 설정 중..."

# 데이터 디렉토리 권한 설정
chown -R postgres:postgres /var/lib/postgresql/data 2>/dev/null || true
chmod -R 700 /var/lib/postgresql/data 2>/dev/null || true

echo "✅ 권한 설정 완료"
