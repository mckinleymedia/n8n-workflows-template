# Repository Usage Instructions

This document helps AI assistants understand how to work with this n8n workflow repository.

## Repository Structure

```
workflows/
├── ai/                  # Instructions for AI assistants (this folder)
├── workflows/           # Common reusable workflows
├── projects/           
│   ├── example-*/      # Example projects (prefixed with 'example-')
│   ├── your-project/   # Real project (no prefix)
│   └── <user-projects>/ # User's own projects (no prefix)
├── scripts/            # Deployment and utility scripts
│   ├── deploy.sh       # Main deployment script
│   └── lib.sh         # Shared functions
└── CLAUDE.md          # Legacy: AI assistant guidelines (being migrated to ai/)
```

## Key Concepts

### 1. Example vs User Projects
- **Example projects**: Always prefixed with `example-` (e.g., `example-pets`)
- **User projects**: Never prefixed with `example-` (e.g., `email-automation`, `data-sync`)
- Examples are meant to be referenced but not modified
- User projects are the actual implementations

### 2. Deployment System
The repository uses a centralized deployment system. See `process.md` for detailed deployment commands and options.

### 3. When Users Fork This Repository

Users will:
1. Fork the repository to their own GitHub account
2. Clone their fork locally
3. Create their own projects in `projects/` folder
4. Periodically pull updates from upstream (original repo)

Help users understand:
- They own their fork and can commit their projects
- They can pull updates to scripts and examples from upstream
- Their projects won't conflict with upstream updates

## Common User Requests

### "Create a new project for X"
1. Check `ai/instructions/general.md` for detailed instructions
2. Create the project structure in `projects/<name>/`
3. Never prefix with `example-` unless they explicitly want an example

### "Deploy my workflows"
1. Always use the existing deploy script
2. Never create new deployment scripts
3. See `process.md` for deployment commands

### "How do I update from the original repo?"
Guide them to:
```bash
# Add upstream remote (one time)
git remote add upstream https://github.com/wmckinley/n8n-workflows-template.git

# Fetch and merge updates
git fetch upstream
git merge upstream/main

# Resolve any conflicts (unlikely if following conventions)
git push origin main
```

### "Convert my existing n8n workflows"
1. Export workflows from n8n as JSON
2. Create appropriate project structure (see `general.md`)
3. Update node positions to follow grid (see `process.md`)
4. Extract hardcoded values to environment variables
5. Add proper triggers (manual + schedule)

## Important Guidelines

1. **Never modify example projects** - They're references for everyone
2. **Always use the deploy script** - Don't create custom deployment
3. **Follow naming conventions** - Consistency is key
4. **Use environment variables** - Never hardcode secrets
5. **Document projects** - Always create README.md and .env.example

## Repository Philosophy

This repository follows a "framework + projects" model:
- **Framework**: Scripts, examples, and common workflows (maintained by repo owner)
- **Projects**: User implementations (maintained by fork owners)

Users benefit from:
- Regular updates to deployment scripts
- New example projects to learn from
- Bug fixes and improvements
- Community-contributed patterns

While maintaining:
- Their own private projects
- Custom configurations
- Full control over their fork