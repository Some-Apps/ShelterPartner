#!/bin/bash

# Script to run Flutter golden tests using Docker
# Golden tests require Docker for consistent rendering across different environments

set -e

echo "Running Flutter golden tests using Docker..."

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: Please run this script from the Flutter/shelter_partner directory"
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required to run golden tests but is not installed."
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    echo "Golden tests require Docker to ensure consistent font rendering and environment across different machines."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is installed but not running."
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "Building Docker image for golden tests..."
docker build -t flutter-golden-tests -f Dockerfile.golden .

echo "Running golden tests in Docker container..."

# Check if --update-goldens flag is present
UPDATE_GOLDENS=false
for arg in "$@"; do
    if [[ "$arg" == *"--update-goldens"* ]]; then
        UPDATE_GOLDENS=true
        break
    fi
done

if [ "$UPDATE_GOLDENS" = true ]; then
    echo "Update goldens mode detected - will copy updated images from container"
    
    # Run tests in a named container so we can copy files from it
    CONTAINER_NAME="golden-tests-$(date +%s)"
    docker run --name "$CONTAINER_NAME" \
        -v "$(pwd)/test:/app/test" \
        -v "$(pwd)/assets:/app/assets" \
        flutter-golden-tests "$@"
    
    # Copy updated golden images from container to host
    echo "Copying updated golden images from container to host..."
    docker cp "$CONTAINER_NAME:/app/test/golden/goldens" "./test/golden/goldens"
    
    # Clean up the container
    docker rm "$CONTAINER_NAME" > /dev/null 2>&1
    
    echo "Golden images updated successfully!"
else
    # Normal test run with mounted volumes
    docker run --rm \
        -v "$(pwd)/test:/app/test" \
        -v "$(pwd)/assets:/app/assets" \
        flutter-golden-tests "$@"
fi

echo "Golden tests completed!"