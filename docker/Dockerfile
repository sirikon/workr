FROM alpine:3.12
RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories
RUN apk add --update --no-cache crystal=0.35.1-r0 shards=0.11.1-r1 musl-dev zlib-dev zlib-static libressl-dev
WORKDIR /builder
COPY ./shard.yml .
COPY ./shard.lock .
RUN shards
COPY ./src ./src
RUN shards
RUN crystal spec
RUN shards build -Dembed_web_assets --release --static
RUN strip bin/workr
