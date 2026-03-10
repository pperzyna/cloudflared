FROM --platform=$TARGETPLATFORM alpine:3.21

ARG CLOUDFLARED_VERSION
ARG TARGETARCH

RUN apk add --no-cache ca-certificates && \
    wget -O /usr/local/bin/cloudflared \
      "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${TARGETARCH}" && \
    chmod +x /usr/local/bin/cloudflared

ENTRYPOINT ["/usr/local/bin/cloudflared"]
