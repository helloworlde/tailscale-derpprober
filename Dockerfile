FROM golang:1.23-alpine AS build-env

WORKDIR /go/src/tailscale

COPY tailscale/go.mod tailscale/go.sum ./
RUN go mod download

COPY tailscale .

ARG TARGETARCH
RUN GOARCH=$TARGETARCH go build -o  derpprobe cmd/derpprobe/derpprobe.go

FROM alpine:3.18
RUN apk add --no-cache ca-certificates

ENV DERP_MAP=https://login.tailscale.com/derpmap/default
ENV LISTEN=:8030
ENV ONCE=false
ENV SPREAD=false
ENV INTERVAL=15s
ENV MESH_INTERVAL=15s
ENV STUN_INTERVAL=15s
ENV TLS_INTERVAL=15s
ENV BW_INTERVAL=0
ENV BW_PROBE_SIZE_BYTES=1_000_000

COPY --from=build-env /go/src/tailscale/derpprobe /usr/local/bin/derpprobe

ENTRYPOINT ["sh", "-c", "/usr/local/bin/derpprobe \
    -derp-map=${DERP_MAP} \
    -listen=${LISTEN} \
    -once=${ONCE} \
    -spread=${SPREAD} \
    -interval=${INTERVAL} \
    -mesh-interval=${MESH_INTERVAL} \
    -stun-interval=${STUN_INTERVAL} \
    -tls-interval=${TLS_INTERVAL} \
    -bw-interval=${BW_INTERVAL} \
    -bw-probe-size-bytes=${BW_PROBE_SIZE_BYTES}"]