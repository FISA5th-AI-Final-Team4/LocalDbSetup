-- ============================================================================
-- PostgreSQL 초기화 스크립트 (스키마 생성 전용)
-- FAQ 및 용어 데이터베이스 테이블 구조 생성
-- 
-- 실행: docker-compose up -d 시 자동 실행됨 (docker-entrypoint-initdb.d)
-- 위치: ./10_init_postgres.sql
-- ============================================================================

-- ============================================================================
-- 1. FAQ 관련 테이블
-- ============================================================================

-- FAQ 카테고리 테이블
CREATE TABLE IF NOT EXISTS faq_categories (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FAQ 테이블
CREATE TABLE IF NOT EXISTS faqs (
    faq_id VARCHAR(20) PRIMARY KEY,
    category_id VARCHAR(10) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    keywords TEXT[],  -- 배열 타입
    search_text TEXT,  -- 전처리된 통합 검색 텍스트
    normalized_keywords TEXT[],  -- 정규화된 키워드 배열
    user_expressions TEXT[],  -- 사용자 표현 배열
    priority INTEGER DEFAULT 5,
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES faq_categories(category_id) ON DELETE CASCADE
);

-- FAQ 검색 최적화 인덱스
CREATE INDEX IF NOT EXISTS idx_faq_category ON faqs(category_id);  -- 카테고리별 필터링
CREATE INDEX IF NOT EXISTS idx_faq_keywords ON faqs USING GIN(keywords);  -- 키워드 배열 검색
CREATE INDEX IF NOT EXISTS idx_faq_priority ON faqs(priority DESC);  -- 우선순위 정렬
CREATE INDEX IF NOT EXISTS idx_faq_views ON faqs(views DESC);  -- 인기 FAQ 정렬
CREATE INDEX IF NOT EXISTS idx_faq_search_text ON faqs USING GIN(to_tsvector('simple', search_text));  -- 전문 검색
CREATE INDEX IF NOT EXISTS idx_faq_normalized_keywords ON faqs USING GIN(normalized_keywords);  -- 정규화 키워드 검색
CREATE INDEX IF NOT EXISTS idx_faq_user_expressions ON faqs USING GIN(user_expressions);  -- 사용자 표현 검색

-- 동의어 매핑 테이블 (synonym_mappings)
CREATE TABLE IF NOT EXISTS synonym_mappings (
    id SERIAL PRIMARY KEY,
    source_term VARCHAR(200) NOT NULL UNIQUE,  -- 사용자 입력 표현
    target_terms TEXT[] NOT NULL,  -- 매핑되는 표준 용어들
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 동의어 검색 최적화 인덱스
CREATE INDEX IF NOT EXISTS idx_synonym_source ON synonym_mappings(source_term);  -- 원본 용어 검색
CREATE INDEX IF NOT EXISTS idx_synonym_targets ON synonym_mappings USING GIN(target_terms);  -- 대상 용어 배열 검색

-- ============================================================================
-- 2. 용어 사전 관련 테이블
-- ============================================================================

-- 용어 카테고리 테이블
CREATE TABLE IF NOT EXISTS term_categories (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 용어 테이블
CREATE TABLE IF NOT EXISTS terms (
    term_id VARCHAR(20) PRIMARY KEY,
    category_id VARCHAR(10) NOT NULL,
    term VARCHAR(200) NOT NULL,
    definition TEXT NOT NULL,
    english VARCHAR(200),
    related_terms TEXT[],  -- 배열 타입
    views INTEGER DEFAULT 0,  -- 조회수
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES term_categories(category_id) ON DELETE CASCADE
);

-- 용어 검색 최적화 인덱스
CREATE INDEX IF NOT EXISTS idx_term_category ON terms(category_id);  -- 카테고리별 필터링
CREATE INDEX IF NOT EXISTS idx_term_name ON terms(term);  -- 용어명 정확 검색
CREATE INDEX IF NOT EXISTS idx_term_related ON terms USING GIN(related_terms);  -- 관련 용어 배열 검색
CREATE INDEX IF NOT EXISTS idx_term_views ON terms(views DESC);  -- 인기 용어 정렬

-- ============================================================================
-- 3. 데이터 적재 (별도 스크립트 사용)
-- ============================================================================
-- 스키마 생성 후 JSON 데이터 적재는 load_data_from_json.sql 사용
-- 
-- 실행 방법:
-- docker exec -i mcp-postgres psql -U mcp_user -d card_qna_db \
--   -v faq_json="$(cat data/qna/faq/card_faq.json)" \
--   -v term_json="$(cat data/qna/term/financial_terms.json)" \
--   < data/qna/load_data_from_json.sql
-- ============================================================================

-- ============================================================================
-- 초기화 완료
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PostgreSQL 스키마 초기화 완료!';
    RAISE NOTICE '- FAQ 테이블: faq_categories, faqs';
    RAISE NOTICE '- 용어 테이블: term_categories, terms';
    RAISE NOTICE '- 검색 인덱스: GIN (배열 검색 최적화)';
    RAISE NOTICE '========================================';
    RAISE NOTICE '다음 단계: JSON 데이터를 적재';
    RAISE NOTICE '========================================';
END $$;
