#!/bin/bash
# 에러 발생 시 즉시 중지
set -e

# docker-compose.yml에서 마운트할 경로를 /init-data/ 로 가정합니다.
# $POSTGRES_USER 와 $POSTGRES_DB 는 Postgres entrypoint 스크립트가
# 자동으로 .env 파일의 값으로 채워줍니다.

echo "--- JSON 데이터 적재 시작 ---"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v faq_json="$(cat /init-data/qna/faq/card_faq.json)" \
     -v term_json="$(cat /init-data/qna/term/financial_terms.json)" \
     -f /init-data/qna/11_load_data_from_json.sql

echo "--- JSON 데이터 적재 완료 ---"