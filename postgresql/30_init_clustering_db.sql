-- ===============================================
-- 소비패턴 기반 카드 추천 시스템 DB 스키마
-- ===============================================
-- 작성일: 2025-11-28
-- 데이터베이스: mydata
-- 
-- [테이블 구조]
-- 1. persona_consumption_data (7행)
--    - persona_id (1-7)의 소비 패턴 데이터
--    - Backend persona 테이블과 연결
--    - 클러스터링 모델 입력용 X 피처
--
-- 2. clustering_result (10,000행)
--    - 사전 학습된 클러스터링 결과
--    - member_number별 X 피처 + cluster_id
--    - 참조용 데이터
--
-- 3. user_card_usage (10,000행)
--    - member_number - cluster_id - primary_card_id 매핑
--    - 클러스터별 주요 사용 카드 정보
--    - 카드 추천 로직에서 사용
--
-- 4. cluster_recommended_cards (7행)
--    - 클러스터별 추천 카드 매핑 테이블 (7행)
--    - 각 클러스터에 가장 적합한 카드 정보
--    - MCP 서버에서 카드 추천 시 사용
-- ===============================================

-- 데이터베이스 전환 (mydata 사용)
\c "mydata";

-- ===============================================
-- 1. persona_consumption_data 테이블
-- ===============================================
-- Backend의 persona 테이블과 1:1 연결
-- persona_id (1-7)별 최근 3개월 소비 패턴 저장
-- 클러스터링 모델 입력용 피처로 사용
-- ===============================================
CREATE TABLE IF NOT EXISTS persona_consumption_data (
    -- Primary Key
    persona_id INTEGER PRIMARY KEY,              -- Backend persona 테이블의 FK (1-7)
    
    -- 클러스터링 피처 (최근 3개월 기준)
    usage_count_r3m INTEGER NOT NULL DEFAULT 0,  -- 신용카드 이용 건수
    usage_amount_r3m BIGINT NOT NULL DEFAULT 0,  -- 신용카드 총 이용 금액
    
    -- 카테고리별 소비 금액
    amount_shopping BIGINT NOT NULL DEFAULT 0,   -- 쇼핑
    amount_food BIGINT NOT NULL DEFAULT 0,       -- 요식업
    amount_transport BIGINT NOT NULL DEFAULT 0,  -- 교통
    amount_medical BIGINT NOT NULL DEFAULT 0,    -- 의료
    amount_payment BIGINT NOT NULL DEFAULT 0,    -- 공과금/납부
    amount_education BIGINT NOT NULL DEFAULT 0,  -- 교육
    amount_leisure BIGINT NOT NULL DEFAULT 0,    -- 여가/레저
    amount_social BIGINT NOT NULL DEFAULT 0,     -- 사교활동
    amount_daily BIGINT NOT NULL DEFAULT 0,      -- 일상생활
    amount_overseas BIGINT NOT NULL DEFAULT 0,   -- 해외 결제
    
    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_persona_consumption_persona_id ON persona_consumption_data(persona_id);

COMMENT ON TABLE persona_consumption_data IS 'persona별 소비 패턴 데이터 (1-7, Backend 연동)';

-- ===============================================
-- 2. clustering_result 테이블
-- ===============================================
-- 사전 학습된 클러스터링 결과 (10,000행)
-- 학습 데이터로 사용된 회원들의 소비 패턴과 클러스터 정보
-- 참조용 데이터 (통계, 검증 등에 활용)
-- ===============================================
CREATE TABLE IF NOT EXISTS clustering_result (
    -- Primary Key
    member_number INTEGER PRIMARY KEY,           -- 발급회원번호 (SYN_ 제거, 예: 96)
    
    -- 클러스터링 입력 피처 (X)
    usage_count_r3m INTEGER NOT NULL,            -- 신용카드 이용 건수 (R3M)
    usage_amount_r3m BIGINT NOT NULL,            -- 신용카드 총 이용 금액 (R3M)
    amount_shopping BIGINT NOT NULL,             -- 쇼핑 금액
    amount_food BIGINT NOT NULL,                 -- 요식 금액
    amount_transport BIGINT NOT NULL,            -- 교통 금액
    amount_medical BIGINT NOT NULL,              -- 의료 금액
    amount_payment BIGINT NOT NULL,              -- 납부 금액
    amount_education BIGINT NOT NULL,            -- 교육 금액
    amount_leisure BIGINT NOT NULL,              -- 여가생활 금액
    amount_social BIGINT NOT NULL,               -- 사교활동 금액
    amount_daily BIGINT NOT NULL,                -- 일상생활 금액
    amount_overseas BIGINT NOT NULL,             -- 해외 결제 금액
    
    -- 클러스터링 결과 (y)
    cluster_id INTEGER NOT NULL,                 -- 할당된 클러스터 번호 (0-N)
    
    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_clustering_result_cluster ON clustering_result(cluster_id);

COMMENT ON TABLE clustering_result IS '학습된 클러스터링 결과 (10000행, 참조용)';

-- ===============================================
-- 3. user_card_usage 테이블
-- ===============================================
-- 회원번호 - 클러스터 - 주 사용 카드 매핑 테이블 (10,000행)
-- 각 회원이 속한 클러스터와 주로 사용하는 카드 정보
-- 카드 추천 시 클러스터별 인기 카드 조회에 사용
-- ===============================================
CREATE TABLE IF NOT EXISTS user_card_usage (
    -- Primary Key
    member_number INTEGER PRIMARY KEY,           -- 발급회원번호 (SYN_ 제거)
    
    -- 클러스터링 정보
    cluster_id INTEGER NOT NULL,                 -- 소속 클러스터 번호
    
    -- 카드 정보
    primary_card_id VARCHAR(50) NOT NULL,        -- 주 사용 카드 ID (cards 테이블 참조)
    
    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_user_card_cluster ON user_card_usage(cluster_id);
CREATE INDEX IF NOT EXISTS idx_user_card_primary_card ON user_card_usage(primary_card_id);

COMMENT ON TABLE user_card_usage IS '회원-클러스터-카드 매핑 (10000행, 추천 로직용)';

-- ===============================================
-- 4. cluster_recommended_cards 테이블
-- ===============================================
-- 클러스터별 추천 카드 매핑 테이블 (7행)
-- 각 클러스터에 가장 적합한 카드 정보
-- MCP 서버에서 카드 추천 시 사용
-- ===============================================
CREATE TABLE IF NOT EXISTS cluster_recommended_cards (
    -- Primary Key
    cluster_id INTEGER PRIMARY KEY,              -- 클러스터 번호 (0-6)
    
    -- 추천 카드 정보
    recommended_card_1 VARCHAR(50) NOT NULL,     -- 1순위 추천 카드
    recommended_card_2 VARCHAR(50) NOT NULL,     -- 2순위 추천 카드
    
    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE cluster_recommended_cards IS '클러스터별 추천 카드 (7행, MCP 서버 추천용)';

-- ===============================================
-- 완료 메시지
-- ===============================================
DO $$
BEGIN
    RAISE NOTICE '✅ 클러스터링 스키마 생성 완료';
    RAISE NOTICE '   • persona_consumption_data';
    RAISE NOTICE '   • clustering_result';
    RAISE NOTICE '   • user_card_usage';
    RAISE NOTICE '   • cluster_recommended_cards';
END $$;
