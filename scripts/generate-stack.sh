#!/bin/bash

# generate-stack.sh - Generate Portainer-ready stack YAML
# Usage: ./generate-stack.sh [custom-image-tag]
# Example: ./generate-stack.sh mycompany/frappe-custom:v15

set -e

CUSTOM_IMAGE_TAG="$1"

# Check if we're in the frappe_docker directory
if [ ! -f "compose.yaml" ]; then
    echo "Error: Please run this script from the frappe_docker directory"
    exit 1
fi

# Set default environment variables
export ERPNEXT_VERSION=${ERPNEXT_VERSION:-v15.84.0}
export DB_PASSWORD=${DB_PASSWORD:-123}
export SITES=${SITES:-"localhost"}
export ROUTER=${ROUTER:-frappe-stack}

# Set custom image variables if provided
if [ -n "$CUSTOM_IMAGE_TAG" ]; then
    export CUSTOM_IMAGE=$(echo "$CUSTOM_IMAGE_TAG" | cut -d: -f1)
    export CUSTOM_TAG=$(echo "$CUSTOM_IMAGE_TAG" | cut -d: -f2)
    echo "Using custom image: $CUSTOM_IMAGE:$CUSTOM_TAG"
fi

# Generate the stack YAML
echo "Generating Portainer stack YAML..."

docker compose \
    -f compose.yaml \
    -f overrides/compose.mariadb.yaml \
    -f overrides/compose.redis.yaml \
    -f overrides/compose.proxy.yaml \
    config > ~/gitops/frappe-stack-template.yaml

# Add traefik-public network to the generated YAML
echo "Adding traefik-public network configuration..."

# Create a temporary file with network configuration
cat > /tmp/network-config.yaml << EOF
networks:
  traefik-public:
    external: true
    name: traefik-public
EOF

# Append network config to the stack
cat /tmp/network-config.yaml >> ~/gitops/frappe-stack-template.yaml

# Add traefik-public network to all services
sed -i '/networks:/a\      - traefik-public' ~/gitops/frappe-stack-template.yaml
sed -i '/^services:/,/^networks:/ s/^  \([a-zA-Z-]*\):$/  \1:\n    networks:\n      - traefik-public/' ~/gitops/frappe-stack-template.yaml

# Clean up
rm -f /tmp/network-config.yaml

echo "Stack template generated: ~/gitops/frappe-stack-template.yaml"
echo ""
echo "To deploy in Portainer:"
echo "1. Copy the contents of ~/gitops/frappe-stack-template.yaml"
echo "2. Create a new stack in Portainer"
echo "3. Paste the YAML content"
echo "4. Set environment variables as needed"
echo "5. Deploy the stack"
