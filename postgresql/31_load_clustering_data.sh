#!/bin/bash
set -e

echo "🔧 클러스터링 데이터 로드 중..."

# mydata로 전환
export PGDATABASE="mydata"

# 1. persona_consumption_data 테이블에 데이터 로드
echo "👤 persona_consumption_data 테이블에 데이터 로드 중..."
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "\COPY persona_consumption_data (persona_id, usage_count_r3m, usage_amount_r3m, amount_shopping, amount_food, amount_transport, amount_medical, amount_payment, amount_education, amount_leisure, amount_social, amount_daily, amount_overseas) FROM '/init-data/clustering/persona_consumption_data.csv' DELIMITER ',' CSV HEADER;"
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "SELECT COUNT(*) AS \"persona_consumption_data 로드 완료\" FROM persona_consumption_data;"

# 2. clustering_result 테이블에 데이터 로드
echo "📊 clustering_result 테이블에 데이터 로드 중..."
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "\COPY clustering_result (member_number, usage_count_r3m, usage_amount_r3m, amount_shopping, amount_food, amount_transport, amount_medical, amount_payment, amount_education, amount_leisure, amount_social, amount_daily, amount_overseas, cluster_id) FROM '/init-data/clustering/clustering_result.csv' DELIMITER ',' CSV HEADER;"
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "SELECT COUNT(*) AS \"clustering_result 로드 완료\" FROM clustering_result;"

# 3. user_card_usage 테이블에 데이터 로드
echo "🎴 user_card_usage 테이블에 데이터 로드 중..."
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "\COPY user_card_usage (member_number, cluster_id, primary_card_id) FROM '/init-data/clustering/user_card_usage.csv' DELIMITER ',' CSV HEADER;"
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "SELECT COUNT(*) AS \"user_card_usage 로드 완료\" FROM user_card_usage;"

# 클러스터별 분포 확인
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "SELECT cluster_id, COUNT(*) as user_count, COUNT(DISTINCT primary_card_id) as unique_cards FROM user_card_usage GROUP BY cluster_id ORDER BY cluster_id;"

# 4. cluster_recommended_cards 테이블에 데이터 로드
echo "💳 cluster_recommended_cards 테이블에 데이터 로드 중..."
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "\COPY cluster_recommended_cards (cluster_id, recommended_card_1, recommended_card_2) FROM '/init-data/clustering/cluster_recommended_cards.csv' DELIMITER ',' CSV HEADER;"
psql -U "$POSTGRES_USER" -d "$PGDATABASE" -c "SELECT * FROM cluster_recommended_cards ORDER BY cluster_id;"

echo "✅ 클러스터링 데이터 로드 완료!"
