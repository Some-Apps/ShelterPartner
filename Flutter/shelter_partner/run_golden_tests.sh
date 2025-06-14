#!/bin/bash

# Script to run Flutter golden tests in a Docker container
# This ensures consistent test environment across different machines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo "Building Docker image for golden tests..."
docker build -t flutter-golden-tests -f Dockerfile.golden .

echo "Running golden tests in Docker container..."
docker run --rm \
    -v "$PROJECT_DIR/test:/app/test" \
    -v "$PROJECT_DIR/assets:/app/assets" \
    flutter-golden-tests "$@"

echo "Golden tests completed!"