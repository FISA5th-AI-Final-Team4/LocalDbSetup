FROM postgres:15-alpine

USER root

# 빌드 도구 설치
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    clang15 \
    llvm15 \
    postgresql-dev

# pg_bigm 다운로드 및 빌드
WORKDIR /tmp
RUN git clone --depth 1 --branch v1.2-20200228 https://github.com/pgbigm/pg_bigm.git && \
    cd pg_bigm && \
    make USE_PGXS=1 && \
    make USE_PGXS=1 install && \
    cd / && rm -rf /tmp/pg_bigm

# 빌드 도구 제거
RUN apk del git make gcc musl-dev clang15 llvm15 postgresql-dev

USER postgres
WORKDIR /
