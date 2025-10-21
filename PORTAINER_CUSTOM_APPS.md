# Portainer Custom Apps Workflow Guide

This guide explains how to deploy custom Frappe apps using Portainer with the `apps.json` approach.

## Overview

The `apps.json` method is the standard way to build custom Frappe images that include your own applications alongside ERPNext. This approach:

- Builds a custom Docker image with your apps pre-installed
- Uses the official Frappe Docker layered build process
- Integrates seamlessly with Portainer for deployment

## Step-by-Step Workflow

### 1. Create apps.json

Create an `apps.json` file defining your custom applications:

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/your-org/custom-app",
    "branch": "main"
  },
  {
    "url": "https://github.com/frappe/helpdesk",
    "branch": "version-15"
  }
]
```

**Key Points:**
- Always include ERPNext as the first app
- Use specific branch names (e.g., `version-15` for stable releases)
- Custom apps should be publicly accessible Git repositories
- Private repos require authentication setup (see Advanced section)

### 2. Build Custom Image

Use the provided helper script to build your custom image:

```bash
# From the frappe_docker directory
./scripts/build-custom-image.sh apps.json mycompany/frappe-custom:v15
```

This script:
- Validates your `apps.json` file
- Encodes it as base64 (required by Docker build)
- Builds using the layered Containerfile for faster builds
- Tags the image with your specified name

### 3. Deploy via Portainer

#### Option A: Using Generated Stack Template

Generate a Portainer-ready stack YAML:

```bash
# For standard ERPNext
./scripts/generate-stack.sh

# For custom image
./scripts/generate-stack.sh mycompany/frappe-custom:v15
```

Then in Portainer:
1. Go to **Stacks** → **Add Stack**
2. Copy contents from `~/gitops/frappe-stack-template.yaml`
3. Paste into the web editor
4. Set environment variables (see Environment Variables section)
5. Deploy the stack

#### Option B: Manual Stack Creation

Create a new stack in Portainer with this template:

```yaml
version: '3.8'

services:
  configurator:
    image: ${CUSTOM_IMAGE:-frappe/erpnext}:${CUSTOM_TAG:-v15.84.0}
    # ... rest of configurator service

  backend:
    image: ${CUSTOM_IMAGE:-frappe/erpnext}:${CUSTOM_TAG:-v15.84.0}
    # ... rest of backend service

  # ... other services

networks:
  traefik-public:
    external: true
    name: traefik-public
```

### 4. Create Sites with Custom Apps

After deployment, create sites via Portainer's console:

1. Go to your stack → **Console** tab
2. Select the `backend` service
3. Run the site creation command:

```bash
# For sites with custom apps
bench new-site --mariadb-user-host-login-scope=% \
  --db-root-password your_db_password \
  --install-app erpnext \
  --install-app hrms \
  --install-app custom-app \
  --admin-password your_admin_password \
  yourdomain.com
```

## Environment Variables

### Required Variables

```env
# Database
DB_PASSWORD=your_secure_password

# Site Configuration
SITES=`yourdomain.com`

# Custom Image (if using custom build)
CUSTOM_IMAGE=mycompany/frappe-custom
CUSTOM_TAG=v15
```

### Optional Variables

```env
# ERPNext Version (for standard images)
ERPNEXT_VERSION=v15.84.0

# Router Configuration
ROUTER=erpnext-prod

# Custom Image Settings
PULL_POLICY=always
RESTART_POLICY=unless-stopped
```

## Advanced Configuration

### Private Repository Authentication

For private Git repositories, you need to modify the build process:

1. **SSH Keys**: Add your SSH key to the Docker build context
2. **Personal Access Tokens**: Use HTTPS URLs with tokens
3. **Build Context**: Include authentication files in build context

Example with SSH:

```bash
# Copy SSH key to build context
cp ~/.ssh/id_rsa ./ssh_key

# Modify apps.json to use SSH URLs
[
  {
    "url": "git@github.com:your-org/private-app.git",
    "branch": "main"
  }
]

# Build with SSH key
docker build \
  --build-arg=APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag="mycompany/frappe-custom:v15" \
  --file=images/layered/Containerfile .
```

### Multi-Environment Setup

For different environments (dev, staging, prod):

1. **Separate apps.json files**:
   - `apps-dev.json` - Development apps
   - `apps-prod.json` - Production apps

2. **Environment-specific builds**:
   ```bash
   ./scripts/build-custom-image.sh apps-dev.json mycompany/frappe-dev:v15
   ./scripts/build-custom-image.sh apps-prod.json mycompany/frappe-prod:v15
   ```

3. **Portainer environments**:
   - Create separate stacks for each environment
   - Use different environment variables
   - Deploy to different domains/subdomains

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check Git repository accessibility
   - Verify branch names exist
   - Ensure apps.json syntax is valid

2. **Site Creation Errors**:
   - Verify database is running
   - Check admin password strength
   - Ensure domain DNS is configured

3. **App Installation Issues**:
   - Check app dependencies in `hooks.py`
   - Verify app compatibility with Frappe version
   - Review container logs for errors

### Debugging Commands

```bash
# Check container logs
docker logs <container-name>

# Access container shell
docker exec -it <container-name> bash

# Check Frappe logs
docker exec -it <backend-container> bench --site <site-name> logs

# Verify app installation
docker exec -it <backend-container> bench --site <site-name> list-apps
```

## Best Practices

1. **Version Control**: Keep `apps.json` files in version control
2. **Image Tagging**: Use semantic versioning for custom images
3. **Testing**: Test custom images in development before production
4. **Backup**: Regular backups of sites and databases
5. **Monitoring**: Set up health checks and monitoring
6. **Security**: Use strong passwords and secure configurations

## Example Workflows

### Adding a New Custom App

1. Add app to `apps.json`
2. Rebuild custom image
3. Update Portainer stack with new image tag
4. Redeploy stack
5. Install app on existing sites

### Updating ERPNext Version

1. Update `ERPNEXT_VERSION` in environment
2. Update apps.json with new ERPNext branch
3. Rebuild custom image
4. Update Portainer stack
5. Migrate sites to new version

This workflow provides a robust, scalable approach to managing custom Frappe applications with Portainer.
