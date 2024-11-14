#!/bin/bash

# Create log directory and file
mkdir -p /var/log
touch /var/log/startup.log
chmod 666 /var/log/startup.log

# Logging setup
exec 1> >(tee /var/log/startup.log) 2>&1

# Enhanced logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling
set -e
trap 'log "Error on line $LINENO"' ERR

# Start services with monitoring
start_service() {
    local service=$1
    log "Starting $service..."
    service $service start
    sleep 2
    
    if ! service $service status; then
        log "Failed to start $service - retrying..."
        service $service restart
        sleep 2
    fi
    
    if service $service status; then
        log "$service started successfully"
        return 0
    else
        log "Failed to start $service after retry"
        return 1
    fi
}

# Configure and start Jupyter
setup_jupyter() {
    log "Configuring Jupyter Lab..."
    mkdir -p ~/.jupyter
    
    cat > ~/.jupyter/jupyter_lab_config.py << EOL
c.ServerApp.password = '$( \
    python3 -c "from jupyter_server.auth import passwd; \
    print(passwd('${JUPYTER_PASSWORD:-1234}'))" \
)'
c.ServerApp.allow_root = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = ${JUPYTER_PORT:-8888}
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/workspace'
c.ServerApp.terminals_enabled = True
c.ServerApp.allow_remote_access = True
c.ServerApp.token = ''
EOL

    cd /workspace
    log "Starting Jupyter Lab..."
    jupyter lab --no-browser &
    JUPYTER_PID=$!
    
    # Wait for Jupyter to start
    local retries=30
    while ! curl -s http://localhost:${JUPYTER_PORT} >/dev/null && [ $retries -gt 0 ]; do
        sleep 1
        retries=$((retries - 1))
    done
    
    if [ $retries -eq 0 ]; then
        log "Failed to start Jupyter Lab"
        return 1
    fi
    
    log "Jupyter Lab started successfully"
    return 0
}

# Setup rclone configuration from network volume
setup_rclone() {
    log "Starting rclone setup..."
    
    # Check if rclone.conf exists in /workspace
    if [ -f "/workspace/rclone.conf" ]; then
        # Create root config directory
        mkdir -p ~/.config/rclone
        
        # Copy config file
        cp /workspace/rclone.conf ~/.config/rclone/
        chmod 600 ~/.config/rclone/rclone.conf
        
        log "✓ Rclone configuration copied from workspace"
    else
        log "! No rclone.conf found in /workspace - skipping setup"
    fi
    
    return 0
}

# Setup ML tools like WANDB and HF
setup_ml_tools() {
    if [ -n "${WANDB_API_KEY-}" ]; then
        log "Configuring Weights & Biases..."
        wandb login "${WANDB_API_KEY}" >/dev/null 2>&1
    fi
    
    if [ -n "${HF_TOKEN-}" ]; then
        log "Configuring Hugging Face..."
        mkdir -p ~/.huggingface
        echo "${HF_TOKEN}" > ~/.huggingface/token
    fi
}

# Verify workspace structure
verify_workspace() {
    log "Verifying workspace structure..."
    local dirs=(
        "/workspace/SimpleTuner/config"
        "/workspace/SimpleTuner/datasets"
        "/workspace/SimpleTuner/output"
        "/workspace/StableSwarmUI/Models/Lora/flux"
        "/workspace/file-scripts"
        "/workspace/.config/rclone"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            chmod 777 "$dir"
        fi
    done
}

# Main execution
log "Starting PyTorch240 v3.4.3 container..."
log "Container Version: $CONTAINER_VERSION"

# Start core services
start_service ssh
start_service nginx

# Setup components in order
verify_workspace
setup_jupyter
setup_rclone
setup_ml_tools

log "All services started. Available at:"
log "- Jupyter Lab: http://localhost:${JUPYTER_PORT}"
log "- SSH: ssh -p ${SSH_PORT} root@localhost"
log "- HTTP: http://localhost:80"

# Keep container running and monitor Jupyter
while true; do
    if ! ps aux | grep jupyter-lab | grep -v grep > /dev/null; then
        log "Jupyter Lab process died - restarting..."
        setup_jupyter
    fi
    sleep 30
done