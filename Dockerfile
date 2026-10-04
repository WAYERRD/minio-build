ARG MINIO_REF=RELEASE.2025-10-15T17-29-55Z

FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS builder

ARG MINIO_REF
ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache \
    git \
    ca-certificates

WORKDIR /src

RUN git clone https://github.com/minio/minio.git . \
    && git checkout "${MINIO_REF}"

RUN LDFLAGS="$(go run buildscripts/gen-ldflags.go)" \
    && CGO_ENABLED=0 \
       GOOS="${TARGETOS}" \
       GOARCH="${TARGETARCH}" \
       go build \
       -trimpath \
       -ldflags "${LDFLAGS}" \
       -o /out/minio .

FROM alpine:3.22

RUN apk add --no-cache \
    ca-certificates \
    curl \
    && mkdir -p /data

COPY --from=builder /out/minio /usr/local/bin/minio

LABEL org.opencontainers.image.source="https://github.com/WAYERRD/minio-build"
LABEL org.opencontainers.image.description="MinIO Community Edition built from archived official source"

EXPOSE 9000 9001

VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/minio"]

CMD ["server", "/data", "--console-address", ":9001"]
