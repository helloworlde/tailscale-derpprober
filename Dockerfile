FROM golang:alpine AS build-env

WORKDIR /go/src/tailscale

COPY tailscale/go.mod tailscale/go.sum ./
RUN go mod download

COPY tailscale .

ARG TARGETARCH
RUN cd /go/src/tailscale/cmd/derpprobe/ && GOARCH=$TARGETARCH CGO_ENABLED=0 go build -ldflags "-s -w" -o /derpprobe

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

COPY --from=build-env /derpprobe /app/derpprobe

ENTRYPOINT ["sh", "-c", "/app/derpprobe \
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