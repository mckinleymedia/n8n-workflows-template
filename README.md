# n8n Workflows Repository

A collection of organized, reusable n8n workflow projects with centralized management scripts. Fork this repository to create and manage your own n8n workflow projects while staying updated with improvements and examples.

## 🚀 Quick Start

> **Note**: n8n Cloud does not support programmatic workflow import/export via API. These scripts are designed for local container instances and self-hosted n8n deployments only. For n8n Cloud users, workflows must be imported/exported manually through the web interface.

### Automated Setup (Recommended)
```bash
# 1. Clone this repo
git clone <repository-url> && cd workflows

# 2. Run the initialization script
./scripts/init.sh

# This automatically detects and supports:
# - Docker / Docker Desktop
# - Podman (Docker alternative)
# - Colima (Mac Docker Desktop alternative)
# - Rancher Desktop
# - Lima/nerdctl
# - Or guides you to install n8n via npm

# 3. Import example workflow
./scripts/deploy.sh -f example

# 4. Open http://localhost:5678 and test!
```

### Alternative Setup Options

**Option 1: npm Installation (No Containers)**
```bash
# Install n8n globally
npm install -g n8n

# Start n8n
n8n start

# Clone repo and import workflows
git clone <repository-url> && cd workflows
./scripts/deploy.sh -f example
```

**Option 2: Podman (Docker Alternative)**
```bash
# Install Podman: https://podman.io/getting-started/installation
podman run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n
```

**Option 3: Colima (Mac Users)**
```bash
# Install and start Colima
brew install colima
colima start

# Then use docker commands as normal
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n
```

**For Self-Hosted n8n**
```bash
# 1. Clone this repo
git clone <repository-url> && cd workflows

# 2. Set your API credentials in .env
cp .env.example .env
# Edit .env and add:
# N8N_API_URL=https://your-n8n-instance.com
# N8N_API_KEY=your-api-key

# 3. Import workflows with --cloud flag
./scripts/deploy.sh --cloud -f example

# Or import a full project
./scripts/deploy.sh --cloud -p pets
```

### More Import Examples

```bash
# Import all workflows from a project
./scripts/deploy.sh -p example-pets

# Import specific workflows (comma-separated)
./scripts/deploy.sh -p example-pets -f config,main

# Import everything
./scripts/deploy.sh --all
```

## 📁 Repository Structure

```
workflows/
├── ai/                 # AI assistant instructions
│   ├── PROJECT_CREATION.md  # How to create new projects
│   └── REPOSITORY_USAGE.md  # Repository conventions
├── projects/           # Project-specific workflows
│   ├── example-pets/   # Example: Configuration patterns & galleries
│   └── your-project/   # Your custom workflows
├── scripts/            # Centralized management scripts
│   ├── deploy.sh       # Universal deployment script  
│   └── lib.sh          # Shared functions library
├── workflows/          # Common reusable workflows
├── CLAUDE.md          # AI assistant guidelines
└── README.md          # This file
```

### Project Naming Convention
- **Example projects**: Prefixed with `example-` (e.g., `example-pets`)
- **Your projects**: No prefix (e.g., `my-automation`, `data-sync`)

## 🎯 Example Project

### Example Projects

**example-pets**: Advanced patterns including configuration, parallel processing, and HTML galleries.
- [View Details](projects/example-pets/README.md)


Use these as templates for your own projects!

## 🍴 For Users: Fork & Stay Updated

### Initial Setup
1. **Fork this repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/n8n-workflows.git
   cd n8n-workflows
   ```

3. **Add upstream remote** to receive updates:
   ```bash
   git remote add upstream https://github.com/wmckinley/n8n-workflows-template.git
   ```

### Creating Your Own Projects
Ask Claude to help! Simply say: "Create a new n8n project for [your use case]"

Or manually:
1. Create a new folder in `projects/` (no `example-` prefix)
2. Follow the patterns from example projects
3. Deploy with: `./scripts/deploy.sh -p your-project`

### Staying Updated
Pull improvements and new examples from upstream:
```bash
# Fetch latest changes
git fetch upstream

# Merge updates (usually no conflicts since your projects are separate)
git merge upstream/main

# Push to your fork
git push origin main
```

Your projects stay safe while you get:
- Script improvements and bug fixes
- New example projects to learn from
- Updated documentation and patterns

## 🔧 Setup

### Prerequisites
- Docker (for local) OR self-hosted n8n instance with API access
- Bash shell (Mac/Linux/WSL on Windows)

### Quick Start

**Local (Docker Compose)**
```bash
# We've included a docker-compose.yml for you!
docker-compose up -d

# n8n is now running at http://localhost:5678
```

**Self-Hosted n8n**
```bash
# 1. Copy and update the environment file
cp .env.example .env
# Edit .env and add your credentials:
# N8N_API_URL=https://your-n8n-instance.com
# N8N_API_KEY=your-api-key

# 2. Import workflows with --cloud flag
./scripts/deploy.sh --cloud -f example

# Projects work great too!
# Each project can have its own N8N_PROJECT_ID in its .env file
./scripts/deploy.sh --cloud -p example-pets
```

### Import Example Workflow

Once n8n is running:

1. **Clone this repository:**
```bash
git clone <repository-url>
cd workflows
# Optional: Start fresh git history
rm -rf .git && git init
```

2. **Import the example workflow:**
```bash
./scripts/deploy.sh -f example
```

3. **Open n8n and test:**
- Visit http://localhost:5678 in your browser
- Find the "Example" workflow
- Click "Execute Workflow"

### How to View Images in n8n

After executing a workflow with images:
1. Click on the **"Download Images"** node (or any node that outputs images)
2. In the output panel, click the **"Binary"** tab (next to Table/JSON/Schema tabs)
3. You'll see thumbnails of all downloaded images
4. Click any thumbnail to view the full-size image

The example requires no credentials or configuration!

## 🛠️ Workflow Management

### Import Options

```bash
# Examples
./scripts/deploy.sh -p pets              # Import project to local
./scripts/deploy.sh --cloud -p pets      # Import project to cloud

# Options
  -p, --project PROJECT    Import all workflows from a project
  -f, --file WORKFLOWS     Import specific workflow(s) (comma-separated)
  --all                    Import everything
  --cloud                  Deploy to cloud instead of local
  --no-env                 Skip environment variable replacement
  -h, --help               Show help message
```

### Export/Download Options

```bash
# Examples
./scripts/download.sh -p project-name    # Download project from local
./scripts/download.sh --cloud --all      # Download everything from self-hosted

# Options
  -p, --project PROJECT    Download all workflows for a project
  -w, --workflow ID        Download specific workflow by ID
  -c, --create PROJECT     Create new empty project with starter workflows
  -l, --list               List all available workflows
  --all                    Download ALL workflows
  --cloud                  Use self-hosted n8n instead of local
  -h, --help               Show help message
```

### Script Features

**Universal Import:**
- Defaults to local deployment (Docker or CLI)
- Use `--cloud` flag for self-hosted n8n deployment
- Self-hosted deployments support full project structure
- Each project can specify `N8N_PROJECT_ID` in its `.env` file
- Root workflows can use `N8N_DEFAULT_PROJECT_ID` for organization
- Automatically detects which deployment method is available
- Handles file copying for Docker containers

**Environment Configuration:**
- Each project uses `.env` files for configuration
- Copy `.env.example` to `.env`
- Fill in your values (API keys, workflow IDs, etc.)
- For self-hosted: Add `N8N_PROJECT_ID` to organize workflows in projects
- Import script automatically applies these values
- Creates backups before modification
- Restores original config after import

**Smart Import Order:**
1. Configuration workflows first
2. Component workflows in middle  
3. Main workflows last

### Workflow Organization

- **Config first**: Configuration workflows are imported before others
- **Master last**: Master/overview pipelines imported after components
- **Clean names**: Workflows prefixed with project name (e.g., "Form Feedback - Config")
- **Grid layout**: Nodes positioned on 250px grid for consistency

## 📝 Creating New Projects

1. **Create project structure:**
```bash
mkdir -p projects/my-project/workflows
cd projects/my-project
```

2. **Create essential files:**
```bash
# Create environment template
cat > .env.example << 'EOF'
# Cloud Project ID (for n8n Cloud deployments)
# N8N_PROJECT_ID=your-project-id

# Schedule Configuration
MY_PROJECT_SCHEDULE_CRON=0 */6 * * *
MY_PROJECT_SCHEDULE_TIMEZONE=America/New_York

# Workflow IDs (populated after import)
MY_PROJECT_CONFIG_WORKFLOW_ID=
MY_PROJECT_MAIN_WORKFLOW_ID=

# API Keys
MY_PROJECT_API_KEY=
EOF

# Create project README
echo "# My Project\n\nProject-specific workflow documentation" > README.md
```

3. **Create workflows following patterns:**

**Config workflow (`config.json`):**
- Single Set node with all configuration
- Position: [250, 300]

**Component workflows:**
- Webhook/Manual trigger at [250, 300]
- 250px spacing between nodes
- Error handlers at y=500

**Main workflow (`main.json`):**
- Schedule trigger at [250, 250]
- Manual trigger at [250, 350]
- Merge at [500, 300]
- Config at [750, 300]
- Components at [1000, 300], [1250, 300], etc.

4. **Import your new project:**
```bash
./scripts/deploy.sh my-project
```

5. **Optional: Add project wrapper script:**
```bash
#!/bin/bash
# projects/my-project/import.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"  
"$ROOT_DIR/scripts/import.sh" my-project "$@"
```

This allows running `./import.sh` from within the project directory.

## 🎨 Workflow Design Patterns

### Naming Conventions
- Projects: `kebab-case` (e.g., `example-pets`, `my-automation`)
- Workflows: `<Project> - <Component>` (e.g., `Form Feedback - Config`)
- Node IDs: `kebab-case` (e.g., `execute-config`)
- Node names: Simple action verbs (e.g., `Collect Data`, not `Execute Data Collection`)

### Node Positioning
- Start at x=250
- 250px horizontal spacing
- Main flow at y=300
- Error handlers at y=500
- Multiple triggers: y=150, 300, 450 (150px spacing)
- Parallel nodes: y=200 and y=400 (200px spacing)

### Main Workflow Pattern
```
Triggers → Merge → Config → Component 1 → Component 2 → ... → Complete
```

### Configuration Pattern
- Config workflow provides all settings
- Main workflow calls config first
- Config passed to all sub-workflows
- Environment variables for secrets

## 🔄 Reusable Workflows

The `workflows/` folder contains reusable workflow components that can be shared across multiple projects or used standalone.

### Available Workflows

#### Example (`example.json`)
A simple, self-contained workflow demonstrating basic n8n features:
- Fetches 5 cat and 5 dog images from public APIs
- Downloads images as binary data
- No credentials or configuration required
- Perfect for testing n8n installation and viewing images

#### Image Viewer (`image-viewer.json`)
Helper workflow for viewing images in n8n:
- Downloads sample images
- Shows multiple ways to view binary data
- Creates HTML viewer with embedded images
- Saves images to disk for external access
- Includes built-in instructions

### Purpose
Generic, project-agnostic workflows providing common functionality:
- Simple examples for learning
- Data formatting and transformation
- Error handling and logging
- Notification utilities
- API integrations
- Authentication helpers
- Data validation
- Reporting templates

### Usage
Call from any project using the Execute Workflow node:
```javascript
// In your project workflow
Execute Workflow Node:
  - Workflow: "Error Handler"
  - Parameters: 
    - error_message: "{{ $json.error }}"
    - workflow_name: "{{ $workflow.name }}"
```

### Naming Convention
Use descriptive names for clarity:
- `Error Handler`
- `Slack Notifier`
- `Email Sender`
- `Example` (for demo workflows)

## 🤝 Contributing

When adding new workflows:
1. Follow existing naming patterns
2. Use 250px grid positioning
3. Include both manual and schedule triggers
4. Document in project README
5. Add `.env.example` for configuration

### Reusable Workflow Guidelines
1. Keep workflows generic - no project-specific logic
2. Use parameters for configuration
3. Document all inputs/outputs
4. Test with multiple projects
5. Version carefully - changes affect all dependent projects

## 📚 Documentation

- [CLAUDE.md](CLAUDE.md) - AI assistant guidelines
- Project READMEs - Specific project documentation

## 🔒 Security

- Never commit `.env` files (gitignored)
- Use n8n credentials for sensitive data
- API keys only in environment variables
- Project IDs can be stored in `.env` for cloud deployments
- Default project ID for root workflows in root `.env`
- Regular credential rotation recommended

## 🐛 Troubleshooting

### Docker not found
```bash
# Install Docker from https://docs.docker.com/get-docker/
```

### Port 5678 already in use
```bash
# Use a different port
docker run -d --name n8n -p 8080:5678 -v n8n_data:/home/node/.n8n n8nio/n8n
# Access at http://localhost:8080
```

### Import script fails
```bash
# Check if n8n container is running
docker ps | grep n8n

# If not running, start it
docker start n8n

# If container doesn't exist, create it
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n
```

### Can't see images in workflow

**The Binary Tab Method (Most Reliable):**
1. Execute the workflow
2. Click on any node that downloads images (e.g., "Download Images")
3. In the output panel, click the **"Binary"** tab (next to Table/JSON/Schema)
4. You'll see thumbnails of all images
5. Click any thumbnail for full-size preview

**Alternative Methods:**
- **Test Webhook**: Use the webhook trigger's test URL to see HTML in browser
- **Save HTML**: Copy HTML output and save as .html file locally
- **Image Viewer Workflow**: Import `image-viewer` workflow for more options:
  ```bash
  ./scripts/deploy.sh -f image-viewer
  ```

### Webhook not working
- Activate the workflow using the toggle in n8n UI
- For testing, use the "Test URL" from the webhook trigger node

## 📄 License

[Your License Here]

## 🙏 Acknowledgments

Built with [n8n](https://n8n.io) - Fair-code licensed workflow automation tool