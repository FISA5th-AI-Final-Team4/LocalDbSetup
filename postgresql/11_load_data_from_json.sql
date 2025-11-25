-- ============================================================================
-- JSON 데이터를 PostgreSQL에 적재
-- ============================================================================
-- JSON 파일의 데이터를 읽어서 PostgreSQL 테이블에 삽입
-- 
-- 실행 방법 (프로젝트 루트에서 실행):
-- docker exec -i mcp-postgres psql -U `mcp_user -d card_qna_db \
--   -v faq_json="$(cat data/qna/faq/card_faq.json)" \
--   -v term_json="$(cat data/qna/term/financial_terms.json)" \
--   < data/qna/load_data_from_json.sql`
--
-- 설명:
-- - psql의 -v 옵션으로 JSON 파일 내용을 변수로 전달
-- - jsonb_array_elements로 JSON 배열을 행으로 변환
-- - ON CONFLICT로 중복 데이터 업데이트 (Upsert)
-- ============================================================================

-- 동의어 매핑 삽입 (synonym_mappings)
INSERT INTO synonym_mappings (source_term, target_terms)
SELECT 
    key::VARCHAR(200),
    ARRAY(SELECT jsonb_array_elements_text(value))
FROM jsonb_each(:'faq_json'::jsonb->'metadata'->'synonym_mappings')
ON CONFLICT (source_term) DO UPDATE SET
    target_terms = EXCLUDED.target_terms,
    updated_at = CURRENT_TIMESTAMP;

-- FAQ 카테고리 삽입
INSERT INTO faq_categories (category_id, category_name, description)
SELECT 
    (elem->>'category_id')::VARCHAR(10),
    (elem->>'category_name')::VARCHAR(100),
    (elem->>'description')::TEXT
FROM jsonb_array_elements(:'faq_json'::jsonb->'categories') AS elem
ON CONFLICT (category_id) DO UPDATE SET
    category_name = EXCLUDED.category_name,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- FAQ 데이터 삽입 (priority 필드 제거, views 유지)
INSERT INTO faqs (faq_id, category_id, question, answer, search_text, normalized_keywords, user_expressions, views, created_at, updated_at)
SELECT 
    (elem->>'faq_id')::VARCHAR(20),
    (elem->>'category_id')::VARCHAR(10),
    (elem->>'question')::TEXT,
    (elem->>'answer')::TEXT,
    (elem->>'search_text')::TEXT,
    ARRAY(SELECT jsonb_array_elements_text(elem->'normalized_keywords')),
    ARRAY(SELECT jsonb_array_elements_text(elem->'user_expressions')),
    COALESCE((elem->>'views')::INTEGER, 0),
    COALESCE((elem->>'created_at')::TIMESTAMP, CURRENT_TIMESTAMP),
    COALESCE((elem->>'updated_at')::TIMESTAMP, CURRENT_TIMESTAMP)
FROM jsonb_array_elements(:'faq_json'::jsonb->'faqs') AS elem
ON CONFLICT (faq_id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    question = EXCLUDED.question,
    answer = EXCLUDED.answer,
    search_text = EXCLUDED.search_text,
    normalized_keywords = EXCLUDED.normalized_keywords,
    user_expressions = EXCLUDED.user_expressions,
    -- views는 기존 값 유지 (업데이트하지 않음)
    updated_at = CURRENT_TIMESTAMP;

-- 용어 카테고리 삽입
INSERT INTO term_categories (category_id, category_name, description)
SELECT 
    (elem->>'category_id')::VARCHAR(10),
    (elem->>'category_name')::VARCHAR(100),
    (elem->>'description')::TEXT
FROM jsonb_array_elements(:'term_json'::jsonb->'categories') AS elem
ON CONFLICT (category_id) DO UPDATE SET
    category_name = EXCLUDED.category_name,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- 용어 데이터 삽입
INSERT INTO terms (term_id, category_id, term, definition, english, related_terms, views, created_at, updated_at)
SELECT 
    (elem->>'term_id')::VARCHAR(20),
    (elem->>'category_id')::VARCHAR(10),
    (elem->>'term')::VARCHAR(200),
    (elem->>'definition')::TEXT,
    (elem->>'english')::VARCHAR(200),
    ARRAY(SELECT jsonb_array_elements_text(elem->'related_terms')),
    COALESCE((elem->>'views')::INTEGER, 0),
    COALESCE((elem->>'created_at')::TIMESTAMP, CURRENT_TIMESTAMP),
    COALESCE((elem->>'updated_at')::TIMESTAMP, CURRENT_TIMESTAMP)
FROM jsonb_array_elements(:'term_json'::jsonb->'terms') AS elem
ON CONFLICT (term_id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    term = EXCLUDED.term,
    definition = EXCLUDED.definition,
    english = EXCLUDED.english,
    related_terms = EXCLUDED.related_terms,
    views = EXCLUDED.views,
    updated_at = CURRENT_TIMESTAMP;

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'JSON 데이터 적재 완료!';
    RAISE NOTICE '동의어 매핑: % 개', (SELECT COUNT(*) FROM synonym_mappings);
    RAISE NOTICE 'FAQ 카테고리: % 개', (SELECT COUNT(*) FROM faq_categories);
    RAISE NOTICE 'FAQ 데이터: % 개', (SELECT COUNT(*) FROM faqs);
    RAISE NOTICE '용어 카테고리: % 개', (SELECT COUNT(*) FROM term_categories);
    RAISE NOTICE '용어 데이터: % 개', (SELECT COUNT(*) FROM terms);
    RAISE NOTICE '========================================';
END $$;
