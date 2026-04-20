FROM alpine:3.20

RUN apk add --no-cache \
      bash \
      gcc \
      make \
      musl-dev \
      coreutils \
      grep \
      diffutils \
      valgrind

WORKDIR /work

COPY . /work

ENTRYPOINT ["/work/src/tests/docker-entrypoint.sh"]