#!/bin/bash

# Local script to run golden tests without Docker
# This is a fallback option for developers who can't use Docker

set -e

echo "Running Flutter golden tests locally..."

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: Please run this script from the Flutter/shelter_partner directory"
    exit 1
fi

# Run golden tests
echo "Executing: flutter test --tags golden $@"
flutter test --tags golden "$@"

echo "Golden tests completed!"