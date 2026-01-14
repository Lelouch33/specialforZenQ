#!/usr/bin/env bash
set -euo pipefail

#################################
# specialforZenQ MLNode Entrypoint
#################################

# Activate virtual environment
source /app/.venv/bin/activate

# B300/GPU specific environment
export TORCH_CUDA_ARCH_LIST="10.3a"
export CUDA_HOME="/usr/local/cuda-13.0"
export TRITON_PTXAS_PATH="${CUDA_HOME}/bin/ptxas"
export TORCHINDUCTOR_DISABLE=1
export TORCH_COMPILE_DISABLE=1
export VLLM_PYTHON_PATH="/app/.venv/bin/python"

# Add CUDA to PATH
export PATH="${CUDA_HOME}/bin:${PATH}"

# Log configuration
echo "======================================"
echo " specialforZenQ MLNode Starting"
echo "======================================"
echo " PYTHONPATH: ${PYTHONPATH}"
echo " HF_HOME: ${HF_HOME}"
echo " CUDA_HOME: ${CUDA_HOME}"
echo " TORCH_CUDA_ARCH_LIST: ${TORCH_CUDA_ARCH_LIST}"
echo "======================================"

# Check GPU
echo "Checking GPU availability..."
nvidia-smi || echo "Warning: nvidia-smi not available"

# List packages for debugging
echo ""
echo "Available packages:"
ls -la /app/packages/ 2>/dev/null || echo "No packages found"

echo ""
echo "Starting MLNode API server..."
echo "======================================"

# Execute the command passed to the container
exec "$@"
