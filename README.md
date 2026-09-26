# cloudflared

Minimal multi-arch Docker image for [cloudflared](https://github.com/cloudflare/cloudflared) based on Alpine Linux. Supports `linux/arm64` and `linux/arm/v7` (32-bit ARM).

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

MikroTik devices running RouterOS 7 with container support are a primary use case for this image. The image is a multi-arch manifest covering both `linux/arm/v7` (32-bit, most MikroTik devices) and `linux/arm64` — RouterOS will automatically pull the correct variant. Tested on hAP ax lite.

### Setup

```
/system/device-mode/update container=yes
```
*(device will reboot to apply)*

```
/container/config/set registry-url=https://ghcr.io tmpdir=flash/tmp

/interface/veth/add name=veth1 dhcp=true

/interface/bridge/port/add bridge=bridge1 interface=veth1

/container/add \
  remote-image=ghcr.io/pperzyna/cloudflared:latest \
  interface=veth1 \
  root-dir=flash/containers/cloudflared \
  hostname=cloudflared \
  logging=yes \
  start-on-boot=yes \
  env="QUIC_GO_DISABLE_RECEIVE_BUFFER_WARNING=true" \
  cmd="tunnel --no-autoupdate run --token <YOUR_TOKEN>"

/container/start 0
```

Monitor pull progress and tunnel status:
```
/log/print follow
```

Get your tunnel token from the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/).

### Notes

- `root-dir=flash/containers/cloudflared` — stores the image on internal flash so it persists across reboots and does not need to be re-downloaded
- `tmpdir=flash/tmp` — uses flash for layer extraction during image pull, avoiding tmpfs exhaustion on devices with limited RAM headroom (e.g. hAP ax lite with 256 MB RAM)
- `QUIC_GO_DISABLE_RECEIVE_BUFFER_WARNING=true` — suppresses a UDP receive buffer warning logged by the QUIC library; the warning is harmless but cannot be resolved on RouterOS as sysctl values are not user-configurable
- The binary is compressed with UPX at build time to minimize image size on flash; it decompresses into RAM at runtime

## Image details

| Property    | Value                  |
|-------------|------------------------|
| cloudflared | `2026.9.3`             |
| Base        | `alpine:3.24`          |
| Platform    | `linux/arm64`, `linux/arm/v7` |
| Contents    | cloudflared binary (UPX compressed) + CA certificates |

The ARM 32-bit binary is dynamically linked and requires musl libc provided by Alpine. The binary is compressed with UPX at build time to reduce image size.

## CI/CD

The versions live in the `Dockerfile` (`ARG CLOUDFLARED_VERSION` and `FROM alpine:`). The GitHub Actions workflow (`.github/workflows/build.yml`):

- Runs daily at 06:00 UTC, checks the latest cloudflared release and the latest stable Alpine branch, and commits any change to the `Dockerfile` and the table above; the same run then builds and pushes `:<version>` and `:latest`
- Builds on every push to `main` that touches the `Dockerfile` or the workflow
- Can be triggered manually with a specific version to backfill an older tag (`:latest` is left alone)

The daily commits also keep the repository active — GitHub disables scheduled workflows in repositories without activity for 60 days. Dependabot keeps the actions current.

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
# ARM64, version from the Dockerfile
docker build --platform linux/arm64 -t cloudflared .

# ARM 32-bit
docker build --platform linux/arm/v7 -t cloudflared:armv7 .
```

To build another version, pass it as a build argument:

```sh
docker build --platform linux/arm64 \
  --build-arg CLOUDFLARED_VERSION=2026.3.0 \
  -t cloudflared:2026.3.0 .
```

### Test

```sh
# Print version (ARM64)
docker run --rm --platform linux/arm64 cloudflared --version

# Print version (ARM 32-bit)
docker run --rm --platform linux/arm/v7 cloudflared:armv7 --version

# Run a named tunnel
docker run --rm --platform linux/arm/v7 cloudflared:armv7 \
  tunnel --no-autoupdate run --token <YOUR_TOKEN>
```
