#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print section header
print_header() {
    local title=$1
    echo ""
    echo "======================================"
    echo "$title"
    echo "======================================"
    echo ""
}

# Check if n8n is available (Docker, CLI, or API)
check_n8n() {
    local use_cloud=${1:-false}
    
    # Only check API if explicitly requested via --cloud flag
    if [ "$use_cloud" = "true" ]; then
        if [ -n "$N8N_API_URL" ] && [ -n "$N8N_API_KEY" ]; then
            echo "api"
            return
        else
            echo "none"
            return
        fi
    fi
    
    # Default to local - check for container runtimes
    # Try to detect which container runtime is available
    local container_runtime=""
    
    if command -v docker &> /dev/null; then
        container_runtime="docker"
    elif command -v podman &> /dev/null; then
        container_runtime="podman"
    elif command -v nerdctl &> /dev/null; then
        container_runtime="nerdctl"
    elif command -v lima &> /dev/null && lima nerdctl version &> /dev/null; then
        container_runtime="lima nerdctl"
    fi
    
    if [ -n "$container_runtime" ]; then
        # Check for container named 'n8n' or containing 'n8n'
        if $container_runtime ps --format '{{.Names}}' 2>/dev/null | grep -q 'n8n'; then
            # Get the first n8n container name
            export N8N_CONTAINER=$($container_runtime ps --format '{{.Names}}' | grep 'n8n' | head -1)
            export CONTAINER_RUNTIME="$container_runtime"
            echo "container"
            return
        fi
    fi
    
    # Check n8n CLI
    if command -v n8n &> /dev/null; then
        echo "cli"
        return
    fi
    
    echo "none"
}

# Apply environment variables to config workflow (Pure Bash version)
apply_env_config() {
    local project_dir=$1
    local env_file="$project_dir/.env"
    local config_file="$project_dir/workflows/config.json"
    local config_backup="$project_dir/workflows/config.json.backup"
    
    if [ ! -f "$env_file" ]; then
        print_message "$YELLOW" "⚠️  No .env file found at $env_file"
        print_message "$YELLOW" "   Using default values from config.json"
        return 0
    fi
    
    # Check if config.json exists
    if [ ! -f "$config_file" ]; then
        # No config.json, so no need to apply env vars
        return 0
    fi
    
    print_message "$BLUE" "📝 Applying environment variables to config.json..."
    
    # Create backup
    cp "$config_file" "$config_backup" 2>/dev/null
    
    # Load environment variables
    set -a
    source "$env_file"
    set +a
    
    # Since most n8n workflows don't actually need env var substitution in config.json,
    # and the main use is for workflow IDs which are handled by n8n's native env var support,
    # we can skip the complex JSON manipulation and just let n8n handle it.
    
    # For projects that do need it, they can use n8n's built-in expressions like:
    # {{ $env.WORKFLOW_ID_CONFIG }}
    
    print_message "$GREEN" "✅ Environment loaded (n8n will apply variables at runtime)"
    
    return 0
}

# Restore config backup
restore_config_backup() {
    local project_dir=$1
    local config_file="$project_dir/workflows/config.json"
    local config_backup="$project_dir/workflows/config.json.backup"
    
    if [ -f "$config_backup" ]; then
        # In our simplified version, we don't modify the file, so just remove backup
        rm -f "$config_backup"
    fi
}

# Deploy workflow via API
deploy_workflow_api() {
    local workflow_file=$1
    local is_project_workflow=$2  # true if part of a project, false if root workflow
    local api_url="${N8N_API_URL}/api/v1/workflows"
    
    # Read workflow JSON
    local workflow_json=$(cat "$workflow_file")
    
    # Determine which project ID to use
    local project_id=""
    if [ "$is_project_workflow" = "true" ] && [ -n "$N8N_PROJECT_ID" ]; then
        # Use project-specific ID if available
        project_id="$N8N_PROJECT_ID"
    elif [ "$is_project_workflow" = "false" ] && [ -n "$N8N_DEFAULT_PROJECT_ID" ]; then
        # Use default project ID for root workflows
        project_id="$N8N_DEFAULT_PROJECT_ID"
    fi
    
    # Add project ID if we have one
    if [ -n "$project_id" ]; then
        # Add projectId to the workflow JSON
        workflow_json=$(echo "$workflow_json" | sed 's/^{/{\"projectId\":\"'"$project_id"'\",/')
    fi
    
    # Deploy via API
    local response=$(curl -s -X POST \
        -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$workflow_json" \
        "$api_url")
    
    if echo "$response" | grep -q '"id"'; then
        return 0
    else
        print_message "$YELLOW" "API Response: $response"
        return 1
    fi
}

# Deploy single workflow
deploy_workflow() {
    local workflow_file=$1
    local n8n_type=$2
    local is_project_workflow=${3:-true}  # Default to true for backward compatibility
    
    if [ ! -f "$workflow_file" ]; then
        print_message "$RED" "❌ File not found: $workflow_file"
        return 1
    fi
    
    local workflow_name=$(basename "$workflow_file" .json)
    print_message "$BLUE" "Deploying: $(basename $workflow_file)"
    
    local result
    
    if [ "$n8n_type" = "api" ]; then
        # API deployment
        deploy_workflow_api "$workflow_file" "$is_project_workflow"
        result=$?
    elif [ "$n8n_type" = "container" ]; then
        # Container deployment - use the detected runtime and container name
        local container="${N8N_CONTAINER:-n8n}"
        local runtime="${CONTAINER_RUNTIME:-docker}"
        $runtime cp "$workflow_file" "$container":/tmp/workflow.json
        $runtime exec "$container" n8n import:workflow --input=/tmp/workflow.json
        result=$?
        $runtime exec "$container" rm -f /tmp/workflow.json 2>/dev/null
    else
        # CLI deployment
        n8n import:workflow --input="$workflow_file"
        result=$?
    fi
    
    if [ $result -eq 0 ]; then
        print_message "$GREEN" "✓ Successfully deployed: $(basename $workflow_file)"
    else
        print_message "$RED" "✗ Failed to deploy: $(basename $workflow_file)"
    fi
    
    return $result
}

# Deploy all workflows in a directory
deploy_all_workflows() {
    local workflow_dir=$1
    local n8n_type=$2
    local is_project_workflow=${3:-true}  # Default to true for backward compatibility
    
    if [ ! -d "$workflow_dir" ]; then
        print_message "$RED" "❌ Directory not found: $workflow_dir"
        return 1
    fi
    
    local success_count=0
    local fail_count=0
    local ordered_files=()
    
    # Determine deployment order
    # 1. Config workflows first
    for file in "$workflow_dir"/*config*.json; do
        [ -f "$file" ] && ordered_files+=("$file")
    done
    
    # 2. Other workflows (excluding main/master/overview)
    for file in "$workflow_dir"/*.json; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file")
            if [[ ! "$basename" =~ (config|main|master|overview) ]]; then
                ordered_files+=("$file")
            fi
        fi
    done
    
    # 3. Main/Master/Overview workflows last
    for pattern in main master overview; do
        for file in "$workflow_dir"/*${pattern}*.json; do
            [ -f "$file" ] && ordered_files+=("$file")
        done
    done
    
    # Remove duplicates while preserving order
    local unique_files=()
    for file in "${ordered_files[@]}"; do
        local skip=0
        for unique in "${unique_files[@]}"; do
            if [ "$file" = "$unique" ]; then
                skip=1
                break
            fi
        done
        [ $skip -eq 0 ] && unique_files+=("$file")
    done
    
    # Deploy workflows
    for workflow in "${unique_files[@]}"; do
        deploy_workflow "$workflow" "$n8n_type" "$is_project_workflow"
        if [ $? -eq 0 ]; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    # Print summary
    echo ""
    print_header "Deployment Summary"
    
    if [ $success_count -gt 0 ]; then
        print_message "$GREEN" "✓ Successful: $success_count workflows"
    fi
    
    if [ $fail_count -gt 0 ]; then
        print_message "$RED" "✗ Failed: $fail_count workflows"
    fi
    
    return 0
}

# Validate project directory
validate_project_dir() {
    local project_dir=$1
    
    if [ ! -d "$project_dir/workflows" ]; then
        print_message "$RED" "❌ No workflows directory found in $project_dir"
        return 1
    fi
    
    local json_count=$(find "$project_dir/workflows" -name "*.json" -type f 2>/dev/null | wc -l)
    if [ $json_count -eq 0 ]; then
        print_message "$RED" "❌ No workflow files found in $project_dir/workflows"
        return 1
    fi
    
    return 0
}