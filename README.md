# specialforZenQ


## Features

- CUDA 13.0
- PyTorch 2.9.0 with CUDA 12.9 support
- vLLM 0.13.0
- Python 3.12
## Quick Start

### 1. Copy Gonka Packages

```bash
# Clone gonka repo (if not already done)
git clone https://github.com/gonka-ai/gonka.git /tmp/gonka

# Copy packages to this directory
cp -r /tmp/gonka/mlnode/packages ./packages
```

### 2. Build Image

```bash
chmod +x build.sh
./build.sh
```

This will create:
- `ghcr.io/Lelouch33/specialforZenQ:latest`
- `ghcr.io/Lelouch33/specialforZenQ:<version>`

### 3. Use in Gonka Docker Compose

In your gonka `local-test-net/docker-compose.yml`, replace the ml-node image:

```yaml
services:
  api:
    image: ghcr.io/Lelouch33/specialforZenQ:latest
    # ... rest of config
```

## Manual Build

```bash
docker build -t ghcr.io/Lelouch33/specialforZenQ:latest .
```

## Push to GHCR

```bash
# Login first
docker login ghcr.io -u Lelouch33

# Push
docker push ghcr.io/Lelouch33/specialforZenQ:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TORCH_CUDA_ARCH_LIST` | `10.3a` | CUDA architecture for  |
| `CUDA_HOME` | `/usr/local/cuda-13.0` | CUDA installation path |
| `HF_HOME` | `/opt/hf-cache` | HuggingFace cache |

## Ports

- `8080` - Main API port

## Health Check

```bash
curl http://localhost:8080/health
```
