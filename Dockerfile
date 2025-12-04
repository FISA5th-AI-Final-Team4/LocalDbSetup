FROM postgres:16-alpine

USER root

# 빌드 도구 및 pg_bigm 설치
RUN apk add --no-cache git make gcc musl-dev clang llvm postgresql-dev && \
    ln -sf /usr/bin/clang /usr/bin/clang-19 && \
    mkdir -p /usr/lib/llvm19/bin && \
    ln -sf /usr/bin/llvm-lto /usr/lib/llvm19/bin/llvm-lto && \
    cd /tmp && \
    git clone https://github.com/pgbigm/pg_bigm.git && \
    cd pg_bigm && \
    make USE_PGXS=1 && \
    make USE_PGXS=1 install && \
    cd / && \
    rm -rf /tmp/pg_bigm && \
    apk del git make gcc musl-dev postgresql-dev

USER postgres
