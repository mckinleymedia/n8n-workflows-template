#!/bin/bash

# Download workflows from n8n local instance or cloud
# Usage: ./download.sh [-p project_name] [-w workflow_id] [--cloud]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared functions
source "$SCRIPT_DIR/lib.sh"

# Source .env file if it exists (for cloud credentials)
if [ -f "$ROOT_DIR/.env" ]; then
    set -a  # Export all variables
    source "$ROOT_DIR/.env"
    set +a  # Stop exporting
fi

# Default to local, can be overridden with --cloud flag
USE_CLOUD=false

# Get API URL based on local/cloud mode
get_api_url() {
    if [ "$USE_CLOUD" = true ]; then
        echo "$N8N_API_URL"
    else
        echo "http://localhost:5678"
    fi
}

# Function to check API credentials
check_credentials() {
    if [ "$USE_CLOUD" = true ]; then
        if [ -z "$N8N_API_URL" ] || [ -z "$N8N_API_KEY" ]; then
            print_message "$RED" "❌ Error: Cloud credentials not found"
            print_message "$YELLOW" "Please add N8N_API_URL and N8N_API_KEY to .env file"
            print_message "$CYAN" "See .env.example for format"
            exit 1
        fi
    else
        # Check if local n8n is running
        if ! curl -s -f "http://localhost:5678/healthz" > /dev/null 2>&1; then
            print_message "$RED" "❌ Error: Local n8n not running on port 5678"
            print_message "$YELLOW" "Start n8n with: docker run -d --name n8n -p 5678:5678 n8nio/n8n"
            exit 1
        fi
    fi
}

# List all workflows
list_workflows() {
    local search_term="$1"  # Optional search term
    local source=$([ "$USE_CLOUD" = true ] && echo "cloud" || echo "local")
    
    print_header "Fetching workflows from $source..."
    
    local base_url=$(get_api_url)
    local api_url="${base_url}/api/v1/workflows"
    local response
    
    if [ "$USE_CLOUD" = true ]; then
        response=$(curl -s -X GET \
            -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
            "$api_url")
    else
        response=$(curl -s -X GET "$api_url")
    fi
    
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
search_term = '$search_term'.lower() if '$search_term' else ''

if 'data' in data:
    workflows = data['data']
    
    # Filter by search term if provided
    if search_term:
        filtered = [w for w in workflows if search_term in w['name'].lower() or search_term in w.get('id', '').lower()]
        print(f'\\nWorkflows matching \"{search_term}\" ({len(filtered)} of {len(workflows)} total):')
        workflows = filtered
    else:
        print(f'\\nAll workflows ({len(workflows)} total):')
    
    # Group by project (words before first dash)
    projects = {}
    standalone = []
    
    for workflow in workflows:
        name = workflow['name']
        if ' - ' in name:
            project = name.split(' - ')[0]
            if project not in projects:
                projects[project] = []
            projects[project].append(workflow)
        else:
            standalone.append(workflow)
    
    # Display grouped by project
    for project in sorted(projects.keys()):
        print(f'\\n  {project}:')
        for w in projects[project]:
            print(f\"    - {w['name']} (ID: {w['id']})\")
    
    if standalone:
        print(f'\\n  Standalone workflows:')
        for w in standalone:
            print(f\"    - {w['name']} (ID: {w['id']})\")
    
    if not workflows:
        print('  No workflows found')
else:
    print('Error fetching workflows:', data)
"
}

# Download specific workflow
download_workflow() {
    local workflow_id=$1
    local project_name=$2
    local base_url=$(get_api_url)
    local api_url="${base_url}/api/v1/workflows/${workflow_id}"
    
    print_message "$BLUE" "Downloading workflow: $workflow_id"
    
    local response
    if [ "$USE_CLOUD" = true ]; then
        response=$(curl -s -X GET \
            -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
            "$api_url")
    else
        response=$(curl -s -X GET "$api_url")
    fi
    
    # Determine output path
    local output_dir
    if [ -n "$project_name" ]; then
        output_dir="$ROOT_DIR/projects/$project_name/workflows"
        mkdir -p "$output_dir"
    else
        output_dir="$ROOT_DIR/workflows"
        mkdir -p "$output_dir"
    fi
    
    # Extract workflow name for filename
    local workflow_name=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
name = data.get('name', '$workflow_id').lower()
# Convert to filename-safe format
name = name.replace(' - ', '-').replace(' ', '-').replace('_', '-')
print(name)
" 2>/dev/null || echo "$workflow_id")
    
    local output_file="$output_dir/${workflow_name}.json"
    
    # Save workflow
    echo "$response" | python3 -m json.tool > "$output_file"
    
    if [ $? -eq 0 ]; then
        print_message "$GREEN" "✅ Downloaded to: $output_file"
    else
        print_message "$RED" "❌ Failed to download workflow"
    fi
}

# Create project structure
create_project_structure() {
    local project_name=$1
    local project_dir="$ROOT_DIR/projects/$project_name"
    
    # Check if project already exists
    if [ -d "$project_dir" ]; then
        print_message "$YELLOW" "⚠️  Project '$project_name' already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "$RED" "❌ Aborted"
            return 1
        fi
        print_message "$YELLOW" "Removing existing project..."
        rm -rf "$project_dir"
    fi
    
    print_message "$BLUE" "Creating project structure for: $project_name"
    
    # Create directories
    mkdir -p "$project_dir/workflows"
    mkdir -p "$project_dir/scripts"
    
    # Create README.md
    cat > "$project_dir/README.md" << EOF
# $project_name

An n8n workflow project.

## Overview

This project contains n8n workflows for $project_name.

## Workflows

Workflows are stored in the \`workflows/\` directory.

## Configuration

Environment variables can be configured in \`.env\`.

## Setup

1. Copy \`.env.example\` to \`.env\`
2. Update the workflow IDs and configuration values
3. Import workflows to your n8n instance

## Import

To import these workflows to your n8n instance:

\`\`\`bash
../../scripts/import.sh -p $project_name
\`\`\`

Generated on: $(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    print_message "$GREEN" "✅ Created README.md"
    
    # Create .env.example with workflow IDs
    local env_file="$project_dir/.env.example"
    echo "# $project_name Environment Configuration" > "$env_file"
    echo "# Generated on: $(date '+%Y-%m-%d %H:%M:%S')" >> "$env_file"
    echo "" >> "$env_file"
    echo "# Workflow IDs" >> "$env_file"
    
    # We'll populate this with actual workflow IDs as we download them
    return 0
}

# Update .env.example with workflow ID
add_workflow_to_env() {
    local project_name=$1
    local workflow_name=$2
    local workflow_id=$3
    local env_file="$ROOT_DIR/projects/$project_name/.env.example"
    
    # Convert workflow name to env variable format
    local env_var_name=$(echo "${project_name}_${workflow_name}_WORKFLOW_ID" | tr '[:lower:]' '[:upper:]' | tr ' -' '_')
    
    # Add to .env.example
    echo "${env_var_name}=${workflow_id}" >> "$env_file"
}

# Download all workflows for a project
download_project() {
    local project_name=$1
    local base_url=$(get_api_url)
    local api_url="${base_url}/api/v1/workflows"
    
    print_header "Downloading project: $project_name"
    
    # Get all workflows first to check if any exist
    local response
    if [ "$USE_CLOUD" = true ]; then
        response=$(curl -s -X GET \
            -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
            "$api_url")
    else
        response=$(curl -s -X GET "$api_url")
    fi
    
    # Check if there are workflows for this project and show what we find
    local has_workflows=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
project_name = '$project_name'

if 'data' in data:
    workflows = data['data']
    # Show all workflow names for debugging
    # print(f'DEBUG: Found {len(workflows)} total workflows', file=sys.stderr)
    
    # Try different matching strategies
    exact_match = [w for w in workflows if project_name.lower() == w['name'].lower()]
    contains_match = [w for w in workflows if project_name.lower() in w['name'].lower()]
    id_match = [w for w in workflows if project_name.lower() == w.get('id', '').lower()]
    
    if exact_match:
        # print(f'DEBUG: Found exact name match: {exact_match[0]["name"]} (ID: {exact_match[0]["id"]})', file=sys.stderr)
        project_workflows = exact_match
    elif id_match:
        # print(f'DEBUG: Found ID match: {id_match[0]["name"]} (ID: {id_match[0]["id"]})', file=sys.stderr)
        project_workflows = id_match
    elif contains_match:
        # print(f'DEBUG: Found {len(contains_match)} workflows containing \"{project_name}\":', file=sys.stderr)
        for w in contains_match[:5]:  # Show first 5 matches
            print(f'  - {w["name"]} (ID: {w["id"]})', file=sys.stderr)
        project_workflows = contains_match
    else:
        # print(f'DEBUG: No workflows found matching \"{project_name}\"', file=sys.stderr)
        # print(f'DEBUG: Available workflow names:', file=sys.stderr)
        for w in workflows[:10]:  # Show first 10
            print(f'  - {w["name"]} (ID: {w.get("id", "no-id")})', file=sys.stderr)
        project_workflows = []
    
    print('true' if project_workflows else 'false')
else:
    # print(f'DEBUG: API response error or no data field', file=sys.stderr)
    print('false')
")
    
    if [ "$has_workflows" = "false" ]; then
        local source=$([ "$USE_CLOUD" = true ] && echo "cloud" || echo "local")
        print_message "$YELLOW" "⚠️  No workflows found for project '$project_name' in $source"
        print_message "$CYAN" "💡 To create a new project, use: $(basename "$0") -c $project_name"
        return 1
    fi
    
    # Only create project structure if workflows were found
    create_project_structure "$project_name"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Only download if there are workflows
    if [ "$has_workflows" = "true" ]; then
        # Track downloaded workflows
        local workflow_count=0
        
        # Filter and download workflows
        echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
project_name = '$project_name'

if 'data' in data:
    workflows = data['data']
    
    # Try different matching strategies
    exact_match = [w for w in workflows if project_name.lower() == w['name'].lower()]
    contains_match = [w for w in workflows if project_name.lower() in w['name'].lower()]
    id_match = [w for w in workflows if project_name.lower() == w.get('id', '').lower()]
    
    # Use the best match
    if exact_match:
        project_workflows = exact_match
    elif id_match:
        project_workflows = id_match
    else:
        project_workflows = contains_match
    
    if project_workflows:
        print(f'Downloading {len(project_workflows)} workflows for project {project_name}')
        for workflow in project_workflows:
            print(f\"WORKFLOW_ID:{workflow['id']}:WORKFLOW_NAME:{workflow['name']}\")
" | while IFS=: read -r prefix workflow_id name_prefix workflow_name; do
        if [ "$prefix" = "WORKFLOW_ID" ]; then
            download_workflow "$workflow_id" "$project_name"
            # Extract clean workflow name and add to .env.example
            local clean_name=$(echo "$workflow_name" | sed "s/${project_name} - //i" | sed 's/ /-/g')
            add_workflow_to_env "$project_name" "$clean_name" "$workflow_id"
            ((workflow_count++))
        else
            echo "$prefix$workflow_id$name_prefix$workflow_name"
        fi
done
    fi
    
    # Add default configuration to .env.example
    local env_file="$ROOT_DIR/projects/$project_name/.env.example"
    echo "" >> "$env_file"
    echo "# Configuration" >> "$env_file"
    echo "# Add any additional configuration values below" >> "$env_file"
    
    print_message "$GREEN" "✅ Project structure created successfully"
    print_message "$CYAN" "📁 Project location: projects/$project_name"
}

# Create a new empty project
create_new_project() {
    local project_name=$1
    
    print_header "Creating new project: $project_name"
    
    # Create project structure
    create_project_structure "$project_name"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Create a basic main workflow
    cat > "$ROOT_DIR/projects/$project_name/workflows/main.json" << EOF
{
  "name": "$project_name - Main",
  "nodes": [
    {
      "parameters": {},
      "id": "manual-trigger",
      "name": "Manual Trigger",
      "type": "n8n-nodes-base.manualTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    }
  ],
  "connections": {},
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "versionId": "1",
  "meta": {
    "instanceId": "$project_name-main"
  },
  "id": "$project_name-main"
}
EOF
    
    # Create a basic config workflow
    cat > "$ROOT_DIR/projects/$project_name/workflows/config.json" << EOF
{
  "name": "$project_name - Config",
  "nodes": [
    {
      "parameters": {
        "jsCode": "return [{\n  json: {\n    // Add your configuration values here\n  }\n}];"
      },
      "id": "config-node",
      "name": "Configuration",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [250, 300]
    }
  ],
  "connections": {},
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "versionId": "1",
  "meta": {
    "instanceId": "$project_name-config"
  },
  "id": "$project_name-config"
}
EOF
    
    # Update .env.example with local workflow IDs
    local env_file="$ROOT_DIR/projects/$project_name/.env.example"
    echo "" >> "$env_file"
    echo "# Configuration" >> "$env_file"
    echo "# Add any additional configuration values below" >> "$env_file"
    local upper_name=$(echo "$project_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    echo "${upper_name}_MAIN_WORKFLOW_ID=$project_name-main" >> "$env_file"
    echo "${upper_name}_CONFIG_WORKFLOW_ID=$project_name-config" >> "$env_file"
    
    print_message "$GREEN" "✅ New project created successfully"
    print_message "$CYAN" "📁 Project location: projects/$project_name"
    print_message "$BLUE" "📝 Created starter workflows: main.json and config.json"
}

# Download ALL workflows
download_all() {
    local base_url=$(get_api_url)
    local api_url="${base_url}/api/v1/workflows"
    local source=$([ "$USE_CLOUD" = true ] && echo "cloud" || echo "local")
    
    print_header "Downloading ALL workflows from $source..."
    
    # Get all workflows
    local response
    if [ "$USE_CLOUD" = true ]; then
        response=$(curl -s -X GET \
            -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
            "$api_url")
    else
        response=$(curl -s -X GET "$api_url")
    fi
    
    # Create all-workflows directory
    local output_dir="$ROOT_DIR/workflows/all-downloads-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$output_dir"
    
    # Download each workflow
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)

if 'data' in data:
    workflows = data['data']
    print(f'Found {len(workflows)} workflows')
    for workflow in workflows:
        print(f\"WORKFLOW_ID:{workflow['id']}:WORKFLOW_NAME:{workflow['name']}\")
else:
    print('Error fetching workflows:', data)
" | while IFS=: read -r prefix workflow_id name_prefix workflow_name; do
    if [ "$prefix" = "WORKFLOW_ID" ]; then
        # Download workflow to all-downloads directory
        local workflow_response
        if [ "$USE_CLOUD" = true ]; then
            workflow_response=$(curl -s -X GET \
                -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
                "${base_url}/api/v1/workflows/${workflow_id}")
        else
            workflow_response=$(curl -s -X GET "${base_url}/api/v1/workflows/${workflow_id}")
        fi
        
        # Clean workflow name for filename
        local clean_name=$(echo "$workflow_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
        local output_file="$output_dir/${clean_name}.json"
        
        echo "$workflow_response" | python3 -m json.tool > "$output_file"
        print_message "$GREEN" "✅ Downloaded: $workflow_name"
    else
        echo "$prefix$workflow_id$name_prefix$workflow_name"
    fi
done
    
    print_message "$GREEN" "✅ All workflows downloaded successfully"
    print_message "$CYAN" "📁 Location: $output_dir"
}

# Main execution
main() {
    local project=""
    local workflow_id=""
    local list_only=false
    local create_only=false
    local download_all=false
    local search_term=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--project)
                project="$2"
                shift 2
                ;;
            -w|--workflow)
                workflow_id="$2"
                shift 2
                ;;
            -l|--list)
                list_only=true
                shift
                # Check if next arg exists and is not a flag
                if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    search_term="$1"
                    shift
                fi
                ;;
            -c|--create)
                create_only=true
                project="$2"
                shift 2
                ;;
            --cloud)
                USE_CLOUD=true
                shift
                ;;
            --all)
                download_all=true
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $(basename "$0") [OPTIONS]

Download workflows from n8n local instance or cloud.

Options:
  -p, --project PROJECT    Download all workflows for a project
  -w, --workflow ID        Download specific workflow by ID
  -l, --list [SEARCH]     List workflows (optionally filtered by search)
  -c, --create PROJECT    Create a new empty project
  --all                   Download ALL workflows
  --cloud                 Download from cloud instead of local
  -h, --help              Show this help message

Examples:
  # List all workflows
  $(basename "$0") -l
  
  # Search for specific workflows
  $(basename "$0") -l my-project
  
  # Download specific workflow
  $(basename "$0") -w workflow-id
  
  # Download all workflows for a project
  $(basename "$0") -p my-project
  
  # Download ALL workflows from local
  $(basename "$0") --all
  
  # Download ALL workflows from cloud
  $(basename "$0") --all --cloud
  
  # Create a new empty project
  $(basename "$0") -c my-project

EOF
                exit 0
                ;;
            *)
                print_message "$RED" "❌ Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Execute based on options
    if [ "$create_only" = true ]; then
        if [ -z "$project" ]; then
            print_message "$RED" "❌ Project name required for create"
            exit 1
        fi
        create_new_project "$project"
    elif [ "$download_all" = true ]; then
        check_credentials
        download_all
    elif [ "$list_only" = true ]; then
        check_credentials
        list_workflows "$search_term"
    elif [ -n "$workflow_id" ]; then
        check_credentials
        download_workflow "$workflow_id" "$project"
    elif [ -n "$project" ]; then
        check_credentials
        download_project "$project"
    else
        check_credentials
        list_workflows
    fi
}

# Run main function
main "$@"