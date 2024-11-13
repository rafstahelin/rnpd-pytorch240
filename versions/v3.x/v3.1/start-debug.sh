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

# Setup workspace and file-scripts
setup_workspace() {
    log "Setting up workspace..."
    cd /workspace

    # Clone/update file-scripts
    if [ ! -d "/workspace/file-scripts/.git" ]; then
        log "Cloning file-scripts..."
        git clone "$GITHUB_REPO" /workspace/file-scripts || log "Warning: Could not clone file-scripts"
    else
        log "Updating file-scripts..."
        (cd /workspace/file-scripts && git pull) || log "Warning: Could not update file-scripts"
    fi

    # Install requirements if they exist
    if [ -f "/workspace/file-scripts/requirements.txt" ]; then
        log "Installing file-scripts requirements..."
        pip install -r /workspace/file-scripts/requirements.txt || log "Warning: Could not install requirements"
    fi
}

# Start Jupyter
start_jupyter() {
    log "Configuring Jupyter..."
    mkdir -p ~/.jupyter
    
    # Configure Jupyter
    cat > ~/.jupyter/jupyter_lab_config.py << EOL
c.ServerApp.password = '$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD:-runpod}'))")'
c.ServerApp.allow_root = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = ${JUPYTER_PORT:-8888}
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/workspace'
c.ServerApp.terminals_enabled = True
c.ServerApp.allow_remote_access = True
EOL

    log "Starting Jupyter Lab..."
    jupyter lab --no-browser &
}

# Main execution
log "Starting PyTorch240 v3.1 Debug services..."

# Start core services
start_service ssh
start_service nginx

# Setup workspace and file-scripts
setup_workspace

# Start Jupyter
start_jupyter

log "Startup complete. Services available at:"
log "- Jupyter Lab: http://localhost:${JUPYTER_PORT}"
log "- SSH: ssh -p ${SSH_PORT} root@localhost"

# Keep container running and show logs
tail -f /var/log/startup.log
