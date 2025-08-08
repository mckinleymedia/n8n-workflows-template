# General Instructions: Creating New Projects

## Initial Setup Check

When a user first starts working with this repository, ask:
"Have you run the initialization script yet? (./scripts/init.sh)"

If NO, guide them:
```bash
# Run the initialization script to set up n8n
./scripts/init.sh
```

This script will:
- Check for Docker installation
- Start n8n if not running
- Create n8n_data directory automatically
- Set up initial configuration

## Creating New Projects

When a user asks you to create a new n8n workflow project, follow these steps:

## 1. Project Structure

Create the following structure under `projects/<project-name>/`:

```
projects/<project-name>/
├── workflows/
│   ├── config.json      # Configuration workflow (optional, for complex projects)
│   ├── component1.json  # Individual component workflows
│   ├── component2.json  
│   └── main.json        # Main orchestrator workflow (if multiple components)
├── .env.example         # Environment variables template
└── README.md           # Project documentation
```

## 2. Naming Conventions

- **Project folders**: Use lowercase with hyphens (e.g., `email-automation`, `data-sync`)
- **DO NOT** prefix with `example-` unless it's meant as an example for others
- **Example projects**: Always prefix with `example-` (e.g., `example-pets`)
- **User projects**: Never prefix with `example-`

## 3. Workflow Creation Pattern

### For Simple Projects (Single Workflow)
Create just one workflow file with:
- Manual trigger for testing
- Schedule trigger if needed
- Core logic nodes
- Error handling

### For Complex Projects (Multiple Workflows)
1. **config.json** - Loads environment variables and configuration
2. **component workflows** - Individual pieces of functionality
3. **main.json** - Orchestrates sub-workflows:
   - Dual triggers (manual + schedule)
   - Calls config first
   - Executes components in sequence
   - Passes config to all sub-workflows

## 4. Node Positioning Rules

See `process.md` for detailed node positioning guidelines and grid patterns.

## 5. Environment Variables

Always create `.env.example` with:
```env
# Project Configuration
ENVIRONMENT=local

# Workflow IDs (auto-filled by deploy script)
WORKFLOW_ID_CONFIG=
WORKFLOW_ID_COMPONENT1=

# Project-specific settings
API_KEY=
WEBHOOK_URL=
```

## 6. README Template

```markdown
# Project Name

Brief description of what this project does.

## Prerequisites
- n8n instance running
- Required API keys or services

## Setup
1. Copy `.env.example` to `.env`
2. Fill in your configuration values
3. Deploy: `./scripts/deploy.sh -p <project-name>`

## Workflows
- **workflow1.json**: Description of what it does
- **workflow2.json**: Description of what it does

## Environment Variables
- `API_KEY`: Description of what API this is for
- `WEBHOOK_URL`: Description of webhook purpose
```

## 7. Deployment

See `process.md` for deployment commands and options.

## Important Rules

1. **Never create example projects unless explicitly asked**
2. **Always ask for clarification if the project purpose is unclear**
3. **Use existing patterns from example-pets for reference**
4. **Keep node names simple and action-oriented**
5. **Include both manual and schedule triggers when appropriate**
6. **Don't hardcode sensitive values - use environment variables**