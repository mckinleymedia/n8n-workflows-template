# Pets Project

Example project demonstrating configuration patterns and parallel processing with cat and dog images.

## Workflows

### Pets - Config (`config.json`)
Configuration workflow providing:
- API endpoints
- Image count settings
- Cache duration
- Feature toggles

### Pets - Main (`main.json`)
Main workflow that:
1. Loads configuration from Config workflow
2. Fetches cat and dog images in parallel
3. Downloads images as binary data
4. Creates HTML gallery with statistics
5. Serves via webhook with caching

## Configuration

The project works out of the box! The `.env.example` contains working defaults:

```bash
# Default workflow IDs (work immediately after deployment)
PETS_CONFIG_WORKFLOW_ID=pets-config
PETS_MAIN_WORKFLOW_ID=pets-main
```

Optional: Copy `.env.example` to `.env` to customize settings.

## Deploy

```bash
./scripts/deploy.sh -p pets
```

## Testing

### Manual Execution
1. Open "Pets - Main" workflow in n8n
2. Click "Execute Workflow"
3. View results in "Create Gallery" node

### Webhook Access
1. Activate the workflow
2. Visit: http://localhost:5678/webhook/pets

## APIs Used

- **The Cat API**: https://api.thecatapi.com/v1/images/search
- **The Dog API**: https://api.thedogapi.com/v1/images/search

No authentication required.

## Troubleshooting

### Workflow Not Found Error
```bash
./scripts/deploy.sh -p pets
```

### Configuration Not Applied
Check PETS_CONFIG_WORKFLOW_ID in .env file