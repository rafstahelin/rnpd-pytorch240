#!/bin/bash
# Ensure Unix line endings (LF)

# Enable strict error checking
set -euo pipefail
IFS=$'\n\t'

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Start SSH
start_ssh() {
    log "Starting SSH service..."
    service ssh start || {
        log "Error starting SSH service"
        return 1
    }
    log "SSH service started successfully"
}

# Start Nginx
start_nginx() {
    log "Starting Nginx service..."
    service nginx start || {
        log "Error starting Nginx service"
        return 1
    }
    log "Nginx service started successfully"
}

# Verify CUDA
verify_cuda() {
    log "Verifying CUDA installation..."
    if python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"; then
        log "CUDA verification successful"
    else
        log "CUDA verification failed - continuing anyway"
    fi
}

# Setup workspace structure
setup_workspace() {
    log "Setting up workspace structure..."
    cd /workspace
    
    # Ensure directories exist
    for dir in file-scripts SimpleTuner StableSwarmUI; do
        if [ ! -d "/workspace/$dir" ]; then
            mkdir -p "/workspace/$dir"
            log "Created /workspace/$dir"
        fi
    done

    # Clone/update file-scripts
    if [ -n "${GITHUB_REPO:-}" ]; then
        if [ ! -d "/workspace/file-scripts/.git" ]; then
            log "Cloning file-scripts repository..."
            git clone "$GITHUB_REPO" /workspace/file-scripts || {
                log "Warning: Could not clone file-scripts repository"
                return 0
            }
        else
            log "Updating file-scripts repository..."
            cd /workspace/file-scripts
            git pull || {
                log "Warning: Could not update file-scripts repository"
                return 0
            }
        fi

        # Install file-scripts requirements
        if [ -f "/workspace/file-scripts/requirements.txt" ]; then
            log "Installing file-scripts requirements..."
            pip install -r /workspace/file-scripts/requirements.txt || {
                log "Warning: Could not install file-scripts requirements"
                return 0
            }
        fi
    fi
}

# Start Jupyter
start_jupyter() {
    log "Starting Jupyter Lab..."
    mkdir -p ~/.jupyter
    cd /workspace
    
    # Enhanced Jupyter configuration
    cat > ~/.jupyter/jupyter_lab_config.py << EOL
c.ServerApp.password = '$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD:-runpod}'))")'
c.ServerApp.allow_root = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = ${JUPYTER_PORT:-8888}
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.terminals_enabled = True
c.TerminalManager.enabled = True
c.ServerApp.root_dir = '/workspace'
c.ServerApp.allow_remote_access = True
c.ServerApp.token = ''
EOL

    # Start Jupyter with explicit terminal support
    jupyter lab --no-browser --ServerApp.terminals_enabled=True &
    log "Jupyter Lab started"
}

# Main execution
log "Starting PyTorch240 v3.0 container services..."

# Initialize services
start_ssh || true    # Continue even if SSH fails
start_nginx || true  # Continue even if Nginx fails
verify_cuda         # Continue even if CUDA check fails
setup_workspace     # Setup workspace structure
start_jupyter       # Start Jupyter

log "All services started successfully"

# Keep container running
tail -f /dev/null
