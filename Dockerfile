FROM alpine:3.21

LABEL org.opencontainers.image.source="https://github.com/pperzyna/cloudflared" \ 
      org.opencontainers.image.description="Minimal cloudflared image for linux/arm64 and linux/arm/v7, based on Alpine Linux"

ARG CLOUDFLARED_VERSION
ARG TARGETARCH

RUN apk add --no-cache ca-certificates && \
    wget -O /usr/local/bin/cloudflared \
      "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${TARGETARCH}" && \
    chmod +x /usr/local/bin/cloudflared

ENTRYPOINT ["/usr/local/bin/cloudflared"]
