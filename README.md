# cloudflared

Minimal multi-arch Docker image for [cloudflared](https://github.com/cloudflare/cloudflared), built on `scratch` for the smallest possible footprint. Supports `linux/arm64` and `linux/arm/v7` (32-bit ARM).

## Image

```
ghcr.io/pperzyna/cloudflared:latest
ghcr.io/pperzyna/cloudflared:<version>
```

## Usage

```sh
# Run a tunnel
docker run --rm ghcr.io/pperzyna/cloudflared:latest tunnel --no-autoupdate run --token <TOKEN>

# Expose a local service
docker run --rm ghcr.io/pperzyna/cloudflared:latest tunnel --no-autoupdate --url http://host.docker.internal:8080
```

## Running on MikroTik RouterOS 7

MikroTik devices running RouterOS 7 with container support are a primary use case for this image. The image is a multi-arch manifest covering both `linux/arm/v7` (32-bit, most MikroTik devices) and `linux/arm64` — Docker will automatically pull the correct variant. Tested on hAP ax lite and hAP ax².

### Prerequisites

- RouterOS 7 with container support enabled (`container: yes` in device mode)
- Set the registry URL:
  ```
  /container/config/set registry-url=https://ghcr.io
  ```
- Optionally set a temp dir on USB for faster image extraction:
  ```
  /container/config/set tmpdir=/usb1-part1/tmp/container-pull
  ```

### Setup

1. Create a virtual ethernet interface:
   ```
   /interface/veth/add name=veth-cloudflared
   ```

2. Add the container:
   ```
   /container/add \
     remote-image=ghcr.io/pperzyna/cloudflared:latest \
     interface=veth-cloudflared \
     hostname=cloudflared \
     dns=1.1.1.1,1.0.0.1 \
     logging=yes \
     start-on-boot=yes \
     cmd="tunnel --no-autoupdate run --token <YOUR_TOKEN>"
   ```

3. Start the container:
   ```
   /container/start number=0
   ```

4. Check logs:
   ```
   /log/print follow
   ```

Get your tunnel token from the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/).

## Image details

| Property  | Value                  |
|-----------|------------------------|
| Base      | `scratch`              |
| Platform  | `linux/arm64`, `linux/arm/v7` |
| Contents  | cloudflared binary + CA certificates |

The image uses a multi-stage build:
1. **`alpine`** — downloads the official cloudflared binary for the target arch and provides CA certificates
2. **`scratch`** — final image contains only the binary and `/etc/ssl/certs/ca-certificates.crt`

## CI/CD

The GitHub Actions workflow (`.github/workflows/docker.yml`) automatically:

- Builds and pushes on every push to `main`
- Runs daily at 06:00 UTC to pick up new cloudflared releases
- Skips the build if the image tag already exists in GHCR
- Can be triggered manually with an optional specific version

## Build and test locally

### Prerequisites

- Docker with Buildx (included in Docker Desktop)
- On non-ARM hosts (e.g. x86 Linux): install QEMU emulation first:
  ```sh
  docker run --privileged --rm tonistiigi/binfmt --install arm64,arm
  ```
  On Apple Silicon Macs this is not needed — `linux/arm64` builds natively (`linux/arm/v7` still requires QEMU).

### Build

```sh
# ARM64
docker build --platform linux/arm64 \
  --build-arg CLOUDFLARED_VERSION=2026.3.0 \
  -t cloudflared:2026.3.0 .

# ARM 32-bit
docker build --platform linux/arm/v7 \
  --build-arg CLOUDFLARED_VERSION=2026.3.0 \
  -t cloudflared:2026.3.0-armv7 .
```

To use the latest version automatically:

```sh
VERSION=$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)

docker build --platform linux/arm64,linux/arm/v7 \
  --build-arg CLOUDFLARED_VERSION=$VERSION \
  -t cloudflared:$VERSION .
```

### Test

```sh
# Print version (ARM64)
docker run --rm --platform linux/arm64 cloudflared:2026.3.0 --version

# Print version (ARM 32-bit)
docker run --rm --platform linux/arm/v7 cloudflared:2026.3.0 --version

# Run a named tunnel
docker run --rm --platform linux/arm/v7 cloudflared:2026.3.0 \
  tunnel --no-autoupdate run --token <YOUR_TOKEN>
```
