# Keep GO_IMAGE aligned with go.mod. Override these for a private registry.
ARG GO_IMAGE=golang:1.27.3
ARG UBUNTU_IMAGE=ubuntu:24.04

FROM --platform=$BUILDPLATFORM ${GO_IMAGE} AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -mod=readonly -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/backup-tool .

FROM ${UBUNTU_IMAGE}
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       mysql-client-core-8.0 ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /build-tool \
    && mysqldump --version \
    && mysql --version

COPY --from=build /out/backup-tool /usr/local/bin/backup-tool
COPY LICENSE THIRD_PARTY_NOTICES.txt /usr/local/share/doc/backup-tool/
WORKDIR /build-tool
# Keep the container available for backups triggered with docker exec.
CMD ["sleep", "infinity"]
