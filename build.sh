#!/usr/bin/env bash
set -euo pipefail

#################################
# specialforZenQ Build Script
# Builds and pushes to GHCR
#################################

GITHUB_USERNAME="Lelouch33"
IMAGE_NAME="specialforZenQ"
REGISTRY="ghcr.io"
FULL_IMAGE="${REGISTRY}/${GITHUB_USERNAME}/${IMAGE_NAME}"

# Version (from git tag or default)
VERSION=${VERSION:-$(git describe --tags --always 2>/dev/null || echo "latest")}

echo "======================================"
echo " Building ${IMAGE_NAME}"
echo "======================================"
echo " Image: ${FULL_IMAGE}:${VERSION}"
echo "======================================"

# Check if packages directory exists
if [ ! -d "packages" ]; then
    echo "ERROR: packages directory not found!"
    echo ""
    echo "Please copy gonka packages first:"
    echo "  cp -r /path/to/gonka/mlnode/packages ./packages"
    echo ""
    exit 1
fi

# Build the image
echo "Building Docker image..."
docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --tag "${FULL_IMAGE}:${VERSION}" \
    --tag "${FULL_IMAGE}:latest" \
    --file Dockerfile \
    .

echo ""
echo "======================================"
echo " Build complete!"
echo "======================================"
echo " Image: ${FULL_IMAGE}:${VERSION}"
echo " Image: ${FULL_IMAGE}:latest"
echo "======================================"

# Ask if user wants to push
read -rp "Push to GitHub Container Registry? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Logging in to GHCR..."
    echo "You may need to create a GitHub personal access token with write:packages scope"
    echo "Token: https://github.com/settings/tokens"
    echo ""

    # Try to login (may already be logged in)
    if echo "${GITHUB_TOKEN:-}" | docker login "${REGISTRY}" -u "${GITHUB_USERNAME}" --password-stdin 2>/dev/null; then
        echo "Logged in via GITHUB_TOKEN"
    else
        docker login "${REGISTRY}" -u "${GITHUB_USERNAME}"
    fi

    echo "Pushing images..."
    docker push "${FULL_IMAGE}:${VERSION}"
    docker push "${FULL_IMAGE}:latest"

    echo ""
    echo "======================================"
    echo " Push complete!"
    echo "======================================"
    echo " Image: ${FULL_IMAGE}:${VERSION}"
    echo " Image: ${FULL_IMAGE}:latest"
    echo ""
    echo "Use in gonka docker-compose:"
    echo "  image: ${FULL_IMAGE}:latest"
    echo "======================================"
else
    echo "Skipping push. Image built locally only."
fi
