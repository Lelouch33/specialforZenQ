# syntax=docker/dockerfile:1.4
################################################################################
# specialforZenQ - MLNode Image for Gonka Network
# Optimized for B300 GPU with CUDA 13.0
# GitHub: https://github.com/Lelouch33
################################################################################

# Base image with CUDA 13.0
FROM nvidia/cuda:13.0.0-devel-ubuntu22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda-13.0 \
    PATH=/usr/local/cuda-13.0/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:${LD_LIBRARY_PATH}

# Install base dependencies
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    tar \
    build-essential \
    pkg-config \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Verify CUDA installation
RUN ls -la ${CUDA_HOME}/bin/ptxas && \
    echo "CUDA 13.0 installed successfully"

################################################################################
# Builder stage - install Python dependencies
################################################################################
FROM base AS builder

WORKDIR /app

# Create virtual environment
RUN python3.12 -m venv /app/.venv
ENV PATH="/app/.venv/bin:${PATH}"

# Upgrade pip
RUN python -m pip install -U pip wheel setuptools

# Install base Python packages
RUN python -m pip install -U \
    uvicorn \
    fastapi \
    starlette \
    "httpx[http2]" \
    toml \
    fire \
    nvidia-ml-py \
    accelerate \
    tiktoken \
    "scipy<1.12" \
    "scikit-learn<1.5" \
    "numpy<=2.2.6" \
    "numba>=0.61,<0.62"

# Install PyTorch with CUDA 12.9 support
RUN python -m pip install --index-url https://download.pytorch.org/whl/cu129 \
    torch==2.9.0+cu129 \
    torchvision==0.24.0+cu129 \
    torchaudio==2.9.0+cu129

# Install vLLM 0.13.0 from git
RUN python -m pip install "git+https://github.com/vllm-project/vllm.git@v0.13.0"

# Install Gonka MLNode packages
# These will be copied from gonka repository
COPY packages /app/packages

# Install Gonka package dependencies
RUN if [ -f /app/packages/common/pyproject.toml ]; then \
        cd /app/packages/common && \
        python -m pip install -e . --no-deps; \
    fi
RUN if [ -f /app/packages/pow/pyproject.toml ]; then \
        cd /app/packages/pow && \
        python -m pip install -e . --no-deps; \
    fi
RUN if [ -f /app/packages/train/pyproject.toml ]; then \
        cd /app/packages/train && \
        python -m pip install -e . --no-deps; \
    fi
RUN if [ -f /app/packages/api/pyproject.toml ]; then \
        cd /app/packages/api && \
        python -m pip install -e .; \
    fi

################################################################################
# Final stage - specialforZenQ MLNode
################################################################################
FROM base AS app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/packages /app/packages

# Set up environment
ENV PATH="/app/.venv/bin:${PATH}" \
    PYTHONPATH="/app" \
    PYTHONUNBUFFERED=1 \
    TORCH_CUDA_ARCH_LIST="10.3a" \
    CUDA_HOME="/usr/local/cuda-13.0" \
    TRITON_PTXAS_PATH="/usr/local/cuda-13.0/bin/ptxas" \
    TORCHINDUCTOR_DISABLE=1 \
    TORCH_COMPILE_DISABLE=1

WORKDIR /app

# Create HF cache directory
RUN mkdir -p /opt/hf-cache
ENV HF_HOME=/opt/hf-cache \
    TRANSFORMERS_CACHE=/opt/hf-cache

# Add PYTHONPATH for all gonka packages
ENV PYTHONPATH="${PYTHONPATH}:/app/packages/api/src"
ENV PYTHONPATH="${PYTHONPATH}:/app/packages/train/src"
ENV PYTHONPATH="${PYTHONPATH}:/app/packages/common/src"
ENV PYTHONPATH="${PYTHONPATH}:/app/packages/pow/src"

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose API port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "-m", "uvicorn", "api.app:app", "--host", "0.0.0.0", "--port", "8080"]
