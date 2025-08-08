#!/bin/bash

# n8n Workflow Repository Initialization Script
# This script helps users set up n8n and the repository for first use

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}n8n Workflow Repository Setup${NC}"
echo -e "${BLUE}==================================${NC}\n"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect available container runtime
CONTAINER_RUNTIME=""
COMPOSE_COMMAND=""

if command_exists docker; then
    CONTAINER_RUNTIME="docker"
    echo -e "${GREEN}✓ Docker is installed${NC}"
    if command_exists docker-compose; then
        COMPOSE_COMMAND="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_COMMAND="docker compose"
    fi
elif command_exists podman; then
    CONTAINER_RUNTIME="podman"
    echo -e "${GREEN}✓ Podman is installed${NC}"
    if command_exists podman-compose; then
        COMPOSE_COMMAND="podman-compose"
    fi
elif command_exists nerdctl; then
    CONTAINER_RUNTIME="nerdctl"
    echo -e "${GREEN}✓ nerdctl is installed${NC}"
    if command_exists nerdctl-compose; then
        COMPOSE_COMMAND="nerdctl compose"
    fi
elif command_exists lima; then
    CONTAINER_RUNTIME="lima"
    echo -e "${GREEN}✓ Lima is installed${NC}"
    # Lima typically uses nerdctl inside
    if lima nerdctl version >/dev/null 2>&1; then
        CONTAINER_RUNTIME="lima nerdctl"
    fi
elif command_exists colima; then
    # Colima is a Docker Desktop alternative for Mac
    if colima status 2>/dev/null | grep -q "Running"; then
        CONTAINER_RUNTIME="docker"
        echo -e "${GREEN}✓ Colima is running (Docker compatible)${NC}"
    else
        echo -e "${YELLOW}⚠ Colima is installed but not running${NC}"
        echo "Start Colima with: colima start"
        exit 1
    fi
else
    echo -e "${RED}❌ No container runtime found${NC}"
    echo ""
    echo "Please install one of the following:"
    echo "  • Docker: https://docs.docker.com/get-docker/"
    echo "  • Podman: https://podman.io/getting-started/installation"
    echo "  • Rancher Desktop: https://rancherdesktop.io/"
    echo "  • Colima (Mac): brew install colima"
    echo "  • Lima (Mac/Linux): brew install lima"
    echo ""
    echo "Or run n8n directly with npm:"
    echo "  npm install -g n8n"
    echo "  n8n start"
    exit 1
fi

# Check if n8n is already running
if $CONTAINER_RUNTIME ps 2>/dev/null | grep -q n8n; then
    echo -e "${GREEN}✓ n8n is already running${NC}"
    echo -e "Access n8n at: ${BLUE}http://localhost:5678${NC}"
else
    echo -e "${YELLOW}n8n is not currently running${NC}"
    echo
    read -p "Would you like to start n8n now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        
        # Check if docker-compose.yml exists and we have a compose command
        if [ -f "docker-compose.yml" ] && [ -n "$COMPOSE_COMMAND" ]; then
            echo -e "${BLUE}Starting n8n with $COMPOSE_COMMAND...${NC}"
            $COMPOSE_COMMAND up -d
            
            # Wait for n8n to be ready
            echo -e "${BLUE}Waiting for n8n to be ready...${NC}"
            sleep 5
            
            # Check if n8n is running
            if $CONTAINER_RUNTIME ps | grep -q n8n; then
                echo -e "${GREEN}✓ n8n started successfully!${NC}"
                echo -e "Access n8n at: ${BLUE}http://localhost:5678${NC}"
            else
                echo -e "${RED}❌ Failed to start n8n${NC}"
                echo "Check logs: $CONTAINER_RUNTIME logs n8n"
                exit 1
            fi
        else
            echo -e "${YELLOW}No docker-compose.yml found or compose not available${NC}"
            echo -e "${BLUE}Starting n8n with $CONTAINER_RUNTIME...${NC}"
            
            # Check if container already exists
            if $CONTAINER_RUNTIME ps -a 2>/dev/null | grep -q n8n; then
                echo "Starting existing n8n container..."
                $CONTAINER_RUNTIME start n8n
            else
                echo "Creating new n8n container..."
                # Podman and nerdctl are Docker-compatible for basic commands
                $CONTAINER_RUNTIME run -d \
                    --name n8n \
                    -p 5678:5678 \
                    -v n8n_data:/home/node/.n8n \
                    -e N8N_BASIC_AUTH_ACTIVE=false \
                    n8nio/n8n
            fi
            
            # Wait for n8n to be ready
            echo -e "${BLUE}Waiting for n8n to be ready...${NC}"
            sleep 5
            
            if $CONTAINER_RUNTIME ps | grep -q n8n; then
                echo -e "${GREEN}✓ n8n started successfully!${NC}"
                echo -e "Access n8n at: ${BLUE}http://localhost:5678${NC}"
            else
                echo -e "${RED}❌ Failed to start n8n${NC}"
                exit 1
            fi
        fi
    fi
fi

# Check for Python 3
if command_exists python3; then
    echo -e "${GREEN}✓ Python 3 is installed${NC}"
elif command_exists python; then
    if python --version 2>&1 | grep -q "Python 3"; then
        echo -e "${GREEN}✓ Python 3 is installed${NC}"
    else
        echo -e "${YELLOW}⚠ Python 3 not found (optional for env processing)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Python not found (optional for env processing)${NC}"
fi

# Check if .env exists
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo
    read -p "Would you like to create .env from .env.example? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env file${NC}"
        echo -e "${YELLOW}Remember to update your .env file with your settings${NC}"
    fi
fi

echo
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo
echo "Next steps:"
echo "1. Access n8n at http://localhost:5678"
echo "2. Deploy example workflows: ./scripts/deploy.sh -f example"
echo "3. Create your first project - ask your AI assistant for help!"
echo
echo "For more information, see README.md"