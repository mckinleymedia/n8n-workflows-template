# Process and Workflow Guidelines

## Development Setup

### Prerequisites
- Container runtime (Docker, Podman, Colima, etc.) OR npm for direct installation
- Python 3 (optional, for environment variable processing)
- Bash shell

### Initial Repository Setup

When a user clones or forks this repository for the first time, ask them:
1. "Do you have n8n already installed?" 
   - If NO: Help them choose a setup method
   - If YES: Proceed with configuration

#### Container Runtime Options

The init script (`./scripts/init.sh`) automatically detects and supports:
- **Docker** - Traditional Docker Desktop
- **Podman** - Rootless, daemonless Docker alternative
- **Colima** - Lightweight Docker Desktop replacement for Mac
- **Lima** - Linux VMs on Mac (with nerdctl)
- **Rancher Desktop** - Kubernetes and container management
- **nerdctl** - Docker-compatible CLI for containerd

#### Setting up n8n

**Option 1: Using init script (Recommended)**
```bash
# Automatically detects your container runtime
./scripts/init.sh
```

**Option 2: Direct npm installation (No containers)**
```bash
# Install n8n globally
npm install -g n8n

# Start n8n
n8n start

# Access n8n at http://localhost:5678
```

**Option 3: Manual container setup**
```bash
# With any Docker-compatible runtime (docker/podman/nerdctl)
<runtime> run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n
```

#### Verify Installation
```bash
# For container runtimes
<runtime> ps | grep n8n

# For npm installation
ps aux | grep n8n

# Check if n8n is accessible
curl http://localhost:5678 || echo "n8n not responding"
```

### Quick Start
```bash
# Deploy all projects and common workflows
./scripts/deploy.sh --all

# Deploy all workflows from a project
./scripts/deploy.sh -p example-pets

# Deploy specific workflow from project
./scripts/deploy.sh -p example-pets -f main

# Deploy workflow from /workflows folder
./scripts/deploy.sh -f example

# Deploy multiple workflows (comma-separated)
./scripts/deploy.sh -p example-pets -f config,main
```

## Common Commands

### Deploy Workflows
```bash
# Always from root directory
./scripts/deploy.sh [OPTIONS]

# Examples
./scripts/deploy.sh -p pets                    # Deploy all workflows from project
./scripts/deploy.sh -p pets -f main            # Deploy single workflow from project
./scripts/deploy.sh -f example                 # Deploy workflow from /workflows folder
./scripts/deploy.sh --no-env -p pets           # Skip environment variables
./scripts/deploy.sh --all                      # Deploy everything
```

### Workflow Management
- Each project has its own `.env` file for configuration
- Config workflows are deployed first, main workflows last
- Environment variables are automatically applied during deploy

## Workflow Design Patterns

### 1. Node Positioning
Always position nodes on a consistent grid for clean layouts:
```javascript
// Standard positioning pattern with proper vertical spacing
const positions = {
  trigger: [250, 300],        // Start position
  sequential: [500, 300],     // +250px horizontal spacing
  next: [750, 300],          // Maintain y=300 for main flow
  errorHandler: [500, 500],   // Error nodes at y=500
  multipleTriggers: {
    schedule: [250, 150],     // Top trigger with 150px spacing
    manual: [250, 300],       // Middle trigger
    webhook: [250, 450],      // Bottom trigger
    merge: [500, 300]         // Merge back to main flow
  },
  parallelNodes: {
    top: [750, 200],          // Parallel nodes need 200px vertical spacing
    bottom: [750, 400],       // To accommodate node text/labels
    merge: [1000, 300]        // Merge back to center
  }
}
```

### 2. Main Workflow Pattern
Every project should have a main workflow that:
1. Supports both manual and schedule triggers
2. Calls config workflow first
3. Passes config to all sub-workflows
4. Maintains simple linear flow
5. Lets sub-workflows handle their own validation

```
Schedule Trigger ─┐
                  ├─→ Merge → Config → Component 1 → Component 2 → ... → Complete
Manual Trigger ───┘
```

### 3. Configuration Management
- Use `.env` files for environment-specific values
- Config workflow loads and centralizes settings
- Pass config object to all sub-workflows
- Never hardcode sensitive values

### 4. Deploy Usage
Projects are deployed using the centralized script from root:
```bash
./scripts/deploy.sh -p <project-name>           # Deploy all workflows
./scripts/deploy.sh -p <project-name> -f <workflow> # Deploy specific workflow
./scripts/deploy.sh -f <workflow>               # Deploy workflow from /workflows folder
./scripts/deploy.sh -p <project> -f <w1>,<w2>      # Deploy multiple workflows
```

## Development Conventions

### Code Organization
1. **No duplication**: Use centralized scripts in `/scripts/`
2. **Single responsibility**: Each workflow does one thing well
3. **Clean dependencies**: Config → Components → Main Workflow
4. **Consistent structure**: All projects follow same patterns

### Workflow Best Practices
1. **Validation in sub-workflows**: Don't clutter main workflow with validation
2. **Error handling**: Each workflow handles its own errors
3. **Clear node names**: Use action verbs, be concise
4. **Grid positioning**: 250px spacing, y=300 main flow
5. **Dual triggers**: Always include manual trigger for testing

### Documentation Requirements
Every project must include:
1. `README.md` with clear overview and setup instructions
2. `.env.example` with all required variables
3. Workflow descriptions in README
4. Deploy examples
5. Prerequisites and dependencies

### When Creating New Workflows
1. Follow the established patterns above
2. Use the centralized deploy system (don't create new scripts)
3. Test with manual trigger before scheduling
4. Document all environment variables
5. Use consistent node positioning (250px grid)
6. Prefix workflow names with project name
7. Keep main workflow simple (just orchestration)

### Example New Project Setup

For detailed project structure and creation steps, see `general.md`.