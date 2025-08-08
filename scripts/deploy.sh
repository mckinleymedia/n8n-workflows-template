#!/bin/bash

# Universal n8n workflow deployment script
# Usage:
#   ./deploy.sh -p <project> [-f <workflow1,workflow2,...>]  # Deploy from project
#   ./deploy.sh -f <workflow1,workflow2,...>                  # Deploy from workflows folder
#   ./deploy.sh -p <project>                                  # Deploy all workflows in project
#   ./deploy.sh --all                                         # Deploy everything

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared functions
source "$SCRIPT_DIR/lib.sh"

# Show usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy n8n workflows from projects or workflows folder.

Options:
  -p, --project PROJECT    Project name (e.g., pets)
  -f, --file WORKFLOWS     Workflow file(s) to deploy (without .json)
                          Can be comma-separated or specified multiple times
  --all                    Deploy all projects and workflows
  --cloud                  Use cloud API (requires N8N_API_URL and N8N_API_KEY)
  --no-env                 Skip applying environment variables
  -h, --help              Show this help message

Examples:
  # Deploy all workflows from a project
  $(basename "$0") -p pets
  
  # Deploy specific workflows from a project
  $(basename "$0") -p pets -f main
  $(basename "$0") -p pets -f config,main
  
  # Deploy workflows from /workflows folder
  $(basename "$0") -f example
  $(basename "$0") -f example,utils,error-handler
  
  # Multiple -f flags also work
  $(basename "$0") -p pets -f config -f main
  
  # Deploy everything
  $(basename "$0") --all

Notes:
  - When -f is used without -p, looks in /workflows folder
  - When -p is used without -f, deploys all workflows in that project
  - Workflows can be comma-separated or use multiple -f flags

EOF
    exit 0
}

# Deploy all projects
deploy_all_projects() {
    local n8n_type=$1
    local apply_env=$2
    
    print_header "Deploying All Projects and Workflows"
    
    # Deploy workflows from root if they exist
    if [ -d "$ROOT_DIR/workflows" ] && [ "$(ls -A "$ROOT_DIR/workflows"/*.json 2>/dev/null)" ]; then
        print_header "Root Workflows"
        deploy_all_workflows "$ROOT_DIR/workflows" "$n8n_type" "false"  # false = not a project workflow
    fi
    
    # Deploy from projects directory
    for project_dir in "$ROOT_DIR/projects/"*/; do
        if [ -d "$project_dir/workflows" ]; then
            local project_name=$(basename "$project_dir")
            print_header "Project: $project_name"
            
            if [ "$apply_env" = "true" ]; then
                apply_env_config "$project_dir"
            fi
            
            deploy_all_workflows "$project_dir/workflows" "$n8n_type" "true"  # true = project workflow
            
            if [ "$apply_env" = "true" ]; then
                restore_config_backup "$project_dir"
            fi
        fi
    done
}

# Deploy specific workflows
deploy_specific_workflows() {
    local workflow_dir=$1
    local n8n_type=$2
    local is_project_workflow=$3
    shift 3
    local workflows=("$@")
    
    for workflow in "${workflows[@]}"; do
        local workflow_file="$workflow_dir/${workflow}.json"
        if [ ! -f "$workflow_file" ]; then
            # Try without adding .json if already included
            workflow_file="$workflow_dir/${workflow}"
            if [ ! -f "$workflow_file" ]; then
                print_message "$RED" "❌ Workflow not found: $workflow"
                print_message "$YELLOW" "Available workflows in $(basename "$workflow_dir"):"
                for file in "$workflow_dir"/*.json; do
                    if [ -f "$file" ]; then
                        print_message "$YELLOW" "  - $(basename "$file" .json)"
                    fi
                done
                continue
            fi
        fi
        deploy_workflow "$workflow_file" "$n8n_type" "$is_project_workflow"
    done
}

# Main execution
main() {
    local project=""
    local workflows=()
    local apply_env=true
    local deploy_all=false
    local use_cloud=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--project)
                project="$2"
                shift 2
                ;;
            -f|--file)
                # Split comma-separated values and add to array
                IFS=',' read -ra ADDR <<< "$2"
                for workflow in "${ADDR[@]}"; do
                    # Trim whitespace
                    workflow=$(echo "$workflow" | xargs)
                    workflows+=("$workflow")
                done
                shift 2
                ;;
            --all)
                deploy_all=true
                shift
                ;;
            --cloud)
                use_cloud=true
                shift
                ;;
            --no-env)
                apply_env=false
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                print_message "$RED" "❌ Unknown option: $1"
                echo ""
                show_usage
                ;;
        esac
    done
    
    # Check n8n availability
    local n8n_type=$(check_n8n "$use_cloud")
    if [ "$n8n_type" = "none" ]; then
        print_message "$RED" "❌ Error: n8n is not available"
        if [ "$use_cloud" = "true" ]; then
            print_message "$YELLOW" "Cloud deployment was requested but credentials are missing."
            print_message "$YELLOW" "Please set:"
            print_message "$YELLOW" "  export N8N_API_URL=https://your-instance.n8n.cloud"
            print_message "$YELLOW" "  export N8N_API_KEY=your-api-key"
        else
            print_message "$YELLOW" "Please use one of these options:"
            print_message "$YELLOW" "  1. Run the init script: ./scripts/init.sh"
            print_message "$YELLOW" "  2. Start n8n with any container runtime (docker/podman/nerdctl):"
            print_message "$YELLOW" "     <runtime> run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n"
            print_message "$YELLOW" "  3. Install n8n CLI: npm install -g n8n"
            print_message "$YELLOW" "  4. Use cloud deployment with --cloud flag (requires API credentials)"
        fi
        exit 1
    fi
    
    local type_msg="$n8n_type"
    if [ "$n8n_type" = "api" ]; then
        type_msg="api ($N8N_API_URL)"
    elif [ "$n8n_type" = "container" ]; then
        type_msg="${CONTAINER_RUNTIME:-docker} (${N8N_CONTAINER:-n8n})"
    fi
    print_message "$GREEN" "✅ Found n8n: $type_msg"
    
    # Deploy all projects if requested
    if [ "$deploy_all" = true ]; then
        deploy_all_projects "$n8n_type" "$apply_env"
        exit $?
    fi
    
    # Determine what to deploy
    local workflow_dir=""
    local project_dir=""
    
    # Handle different parameter combinations
    if [ ${#workflows[@]} -gt 0 ] && [ -z "$project" ]; then
        # -f without -p: Deploy from root workflows folder
        workflow_dir="$ROOT_DIR/workflows"
        if [ ! -d "$workflow_dir" ]; then
            print_message "$RED" "❌ Error: No workflows folder found at root"
            exit 1
        fi
        print_header "Root Workflow Deployment"
        
    elif [ -n "$project" ]; then
        # Normal project
        project_dir="$ROOT_DIR/projects/$project"
        if [ ! -d "$project_dir" ]; then
            print_message "$RED" "❌ Error: Project not found: $project"
            print_message "$YELLOW" "Available projects:"
            for dir in "$ROOT_DIR/projects/"*/; do
                if [ -d "$dir/workflows" ]; then
                    print_message "$YELLOW" "  - $(basename "$dir")"
                fi
            done
            exit 1
        fi
        workflow_dir="$project_dir/workflows"
        print_header "Project: $project"
        
    else
        # No parameters provided
        print_message "$RED" "❌ Error: Please specify a project (-p) or workflow file(s) (-f)"
        echo ""
        show_usage
    fi
    
    # Validate workflow directory
    if [ ! -d "$workflow_dir" ]; then
        print_message "$RED" "❌ Error: Workflow directory not found: $workflow_dir"
        exit 1
    fi
    
    # Apply environment configuration if needed (for projects only)
    if [ -n "$project_dir" ] && [ "$apply_env" = true ] && [ -f "$project_dir/.env" ]; then
        apply_env_config "$project_dir"
    fi
    
    # Determine if this is a project workflow
    local is_project_workflow="true"
    if [ -z "$project_dir" ]; then
        # Root workflows are not part of a project
        is_project_workflow="false"
    fi
    
    # Deploy workflows
    if [ ${#workflows[@]} -gt 0 ]; then
        # Deploy specific workflows
        deploy_specific_workflows "$workflow_dir" "$n8n_type" "$is_project_workflow" "${workflows[@]}"
    else
        # Deploy all workflows in directory
        deploy_all_workflows "$workflow_dir" "$n8n_type" "$is_project_workflow"
    fi
    
    # Restore config backup if it was created
    if [ -n "$project_dir" ] && [ "$apply_env" = true ]; then
        restore_config_backup "$project_dir"
    fi
    
    print_message "$BLUE" ""
    print_message "$BLUE" "Check your n8n instance at http://localhost:5678"
}

# Run main function
main "$@"