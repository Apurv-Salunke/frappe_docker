#!/bin/bash

# build-custom-image.sh - Build custom Frappe image with apps.json
# Usage: ./build-custom-image.sh <apps.json> <image-tag>
# Example: ./build-custom-image.sh apps.json mycompany/frappe-custom:v15

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <apps.json> <image-tag>"
    echo "Example: $0 apps.json mycompany/frappe-custom:v15"
    exit 1
fi

APPS_JSON_FILE="$1"
IMAGE_TAG="$2"

# Check if apps.json exists
if [ ! -f "$APPS_JSON_FILE" ]; then
    echo "Error: apps.json file '$APPS_JSON_FILE' not found"
    exit 1
fi

# Check if we're in the frappe_docker directory
if [ ! -f "images/layered/Containerfile" ]; then
    echo "Error: Please run this script from the frappe_docker directory"
    exit 1
fi

echo "Building custom Frappe image with apps from: $APPS_JSON_FILE"
echo "Image tag: $IMAGE_TAG"

# Generate base64-encoded apps.json
echo "Encoding apps.json..."
APPS_JSON_BASE64=$(base64 -w 0 "$APPS_JSON_FILE")

# Build the image
echo "Building Docker image..."
docker build \
    --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
    --build-arg=FRAPPE_BRANCH=version-15 \
    --build-arg=APPS_JSON_BASE64="$APPS_JSON_BASE64" \
    --tag="$IMAGE_TAG" \
    --file=images/layered/Containerfile .

echo "Build completed successfully!"
echo "Image: $IMAGE_TAG"
echo ""
echo "Next steps:"
echo "1. Push image to registry (if needed): docker push $IMAGE_TAG"
echo "2. Use this image in your Portainer stack by setting:"
echo "   CUSTOM_IMAGE=$(echo $IMAGE_TAG | cut -d: -f1)"
echo "   CUSTOM_TAG=$(echo $IMAGE_TAG | cut -d: -f2)"
