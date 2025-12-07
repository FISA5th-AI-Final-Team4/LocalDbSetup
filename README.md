# 챗봇의 정석 DB 서버

| 소개 | 관련 링크 |
| ------ | ------ |
| 챗봇의 정석의 **데이터 인프라를 담당하는 DB 서버 원격 저장소**입니다.<br>PostgreSQL을 통해 **채팅/로그 DB**, **사용자 소비 데이터 DB**, **FAQ·금융 용어 QnA DB**를 분리하여 관리하며,<br> 초기 스키마 및 시딩 데이터를 SQL 스크립트로 자동 설정합니다.<br>또한 Qdrant 기반 **벡터 DB**를 함께 구성하여 카드 설명서 임베딩, RAG·GraphRAG 검색 등 벡터 기반 기능을 지원하고,<br> Docker Compose를 통해 로컬·서버 환경에서 일관된 DB 구성을 제공합니다. | 🔗[챗봇의 정석](https://github.com/FISA5th-AI-Final-Team4) <br>🔗[FrontEnd](https://github.com/FISA5th-AI-Final-Team4/FrontEnd) <br>🔗[BackEnd](https://github.com/FISA5th-AI-Final-Team4/BackEnd) <br>🔗[LLM서버](https://github.com/FISA5th-AI-Final-Team4/LLMServer) <br>🔗[MCP서버](https://github.com/FISA5th-AI-Final-Team4/MCPServer) |


## 🗃️ ERD
- **ChatDB** : 채팅/로그 관리
  
  <img width="720"  alt="image" src="https://github.com/user-attachments/assets/3500bcac-b8dc-4933-828e-62959d570402" />

- **card_qna_db** : FAQ 맟 금융 용어 데이터 관리

  <img width="450" alt="image" src="https://github.com/user-attachments/assets/b8d083a1-b9cf-4fe5-8cf3-a5baa790de37" />

- **Clustering** : 사용자 소비 데이터 관리

  <img width="460" alt="image" src="https://github.com/user-attachments/assets/f93a9a17-3fd6-456b-8f73-e40c8b8c02c2" />


## ⚒️ 기술 스택

- PostgreSQL, Qdrant, Docker

    <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=PostgreSQL&logoColor=white"/> <img src="https://img.shields.io/badge/Qdrant-DC244C?style=for-the-badge"> <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=Docker&logoColor=white">

## 📁 프로젝트 구조
```bash
.
├── Dockerfile                             # 데이터베이스 서버용 Docker 빌드 설정
├── docker-compose.yml                     # DB 서버 실행용 Docker Compose 설정
├── mount                                  # Docker 볼륨 마운트용 데이터 디렉토리
│   ├── postgres_data                      # PostgreSQL 데이터
│   └── vectordb_data                      # Qdrant 벡터 DB 데이터
├── postgresql                             # PostgreSQL 초기화 스크립트
│   ├── 10_init_postgres.sql
│   ├── 11_load_data_from_json.sh
│   ├── 11_load_data_from_json.sql
│   ├── 20_init_backend_db.sql
│   ├── 30_init_clustering_db.sql
│   ├── 31_load_clustering_data.sh
│   ├── clustering                         # 클러스터링 관련 시딩 데이터
│   │   ├── cluster_recommended_cards.csv
│   │   ├── clustering_result.csv
│   │   ├── persona_consumption_data.csv
│   │   └── user_card_usage.csv
│   └── data                               # 금융 용어 및 FAQ 시딩 데이터
│       └── qna
│           ├── faq
│           └── term
└── qdrant                                 # Qdrant 벡터 DB 데이터
    └── data 
        └── Qdrant_DB
```

## ⚙️ 환경 변수 & 서버 실행
- 환경 변수 (`.env`)
    ```bash
    POSTGRES_HOST=http://127.0.0.1
    POSTGRES_PORT=5432
    POSTGRES_DB=card_qna_db
    POSTGRES_USER=your_pg_username
    POSTGRES_PASSWORD=your_pg_password
    ```

- 서버 실행 
    ```bash
    # Docker Compose로 PostgreSQL 및 Qdrant 컨테이너 실행
    docker compose --env-file .env up -d --build
    ```
