#!/bin/bash

# Enable logging
exec 1> >(tee -a /var/log/startup.log) 2>&1

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Start services with basic health check
start_service() {
    local service=$1
    log "Starting $service..."
    service $service start || log "Warning: Failed to start $service"
    sleep 2
}

# Setup workspace and file-scripts with enhanced error handling
setup_file_scripts() {
    log "Setting up file-scripts environment..."
    cd /workspace

    # Validate environment
    if [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_BRANCH" ]; then
        log "Error: GITHUB_REPO or GITHUB_BRANCH environment variable not set"
        return 1
    fi

    local TOOLS_PATH="/workspace/file-scripts/tools"

    # Check for existing installation
    if [ -d "/workspace/file-scripts/.git" ]; then
        log "Updating existing file-scripts installation..."
        cd /workspace/file-scripts
        
        # Fetch all branches
        git fetch --all || log "Warning: Could not fetch updates"
        
        # Check current branch
        local current_branch=$(git rev-parse --abbrev-ref HEAD)
        
        if [ "$current_branch" != "$GITHUB_BRANCH" ]; then
            log "Switching to $GITHUB_BRANCH branch..."
            git checkout $GITHUB_BRANCH || log "Warning: Could not switch branches"
        fi
        
        # Pull latest changes
        if git pull origin $GITHUB_BRANCH; then
            log "file-scripts updated successfully to latest $GITHUB_BRANCH"
        else
            log "Warning: Could not update file-scripts, using existing version"
        fi
    else
        log "Performing fresh file-scripts installation..."
        if git clone -b $GITHUB_BRANCH "$GITHUB_REPO" /workspace/file-scripts; then
            log "file-scripts cloned successfully from $GITHUB_BRANCH branch"
        else
            log "Error: Failed to clone file-scripts"
            return 1
        fi
    fi

    # Validate tools directory
    if [ ! -d "$TOOLS_PATH" ]; then
        log "Error: Tools directory not found after clone/pull"
        return 1
    fi

    # Install dependencies
    if [ -f "/workspace/file-scripts/requirements.txt" ]; then
        log "Installing file-scripts requirements..."
        if pip install -r /workspace/file-scripts/requirements.txt; then
            log "Requirements installed successfully"
        else
            log "Warning: Could not install some requirements"
        fi
    fi

    log "file-scripts setup completed successfully"
}

# Start Jupyter with enhanced configuration
start_jupyter() {
    log "Configuring Jupyter..."
    mkdir -p ~/.jupyter
    
    # Configure Jupyter with better defaults
    cat > ~/.jupyter/jupyter_lab_config.py << EOL
c.ServerApp.password = '$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD:-runpod}'))")'
c.ServerApp.allow_root = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = ${JUPYTER_PORT:-8888}
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/workspace'
c.ServerApp.terminals_enabled = True
c.ServerApp.allow_remote_access = True
c.ServerApp.token = ''
EOL

    log "Starting Jupyter Lab..."
    jupyter lab --no-browser &
}

# Verify workspace setup
verify_workspace() {
    local required_dirs=(
        "/workspace/file-scripts"
        "/workspace/SimpleTuner/config"
        "/workspace/SimpleTuner/datasets"
        "/workspace/SimpleTuner/output"
        "/workspace/StableSwarmUI/Models/Lora/flux"
    )

    log "Verifying workspace structure..."
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log "Warning: Required directory $dir not found, creating..."
            mkdir -p "$dir"
            chmod 777 "$dir"
        fi
    done
}

# Main execution
log "Starting PyTorch240 v3.2 Debug services..."

# Start core services
start_service ssh
start_service nginx

# Setup and verify workspace
verify_workspace
setup_file_scripts

# Start Jupyter
start_jupyter

log "Startup complete. Services available at:"
log "- Jupyter Lab: http://localhost:${JUPYTER_PORT}"
log "- SSH: ssh -p ${SSH_PORT} root@localhost"

# Keep container running and show logs
tail -f /var/log/startup.log
