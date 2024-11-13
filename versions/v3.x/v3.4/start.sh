#!/bin/bash

# Create log directory and file
mkdir -p /var/log
touch /var/log/startup.log
exec 1> >(tee /var/log/startup.log) 2>&1

# Logging function
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
    
    if ! service $service status > /dev/null 2>&1; then
        log "Failed to start $service - retrying..."
        service $service restart
        sleep 2
        
        if ! service $service status > /dev/null 2>&1; then
            log "Failed to start $service after retry"
            return 1
        fi
    fi
    
    log "$service started successfully"
    return 0
}

# Configure and start Jupyter
setup_jupyter() {
    log "Configuring Jupyter Lab..."
    mkdir -p ~/.jupyter
    
    cat > ~/.jupyter/jupyter_server_config.py << EOL
c.ServerApp.password = '$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD:-1234}'))")'
c.ServerApp.allow_root = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = ${JUPYTER_PORT:-8888}
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/workspace'
c.ServerApp.terminals_enabled = True
c.ServerApp.allow_remote_access = True
c.ServerApp.token = ''
EOL

    chmod 600 ~/.jupyter/jupyter_server_config.py
    
    cd /workspace
    jupyter lab --no-browser &
    JUPYTER_PID=$!
    sleep 5
    
    if ! ps -p $JUPYTER_PID > /dev/null; then
        log "Failed to start Jupyter Lab"
        return 1
    fi
    
    # Check if Jupyter is responding
    local retries=30
    while ! curl -s http://localhost:${JUPYTER_PORT:-8888} > /dev/null; do
        sleep 1
        retries=$((retries - 1))
        if [ $retries -eq 0 ]; then
            log "Jupyter Lab failed to respond"
            return 1
        fi
    done
    
    log "Jupyter Lab started successfully"
    return 0
}

# Setup ML tools
setup_ml_tools() {
    if [ -n "${HF_TOKEN-}" ]; then
        log "Configuring HuggingFace..."
        echo -n "${HF_TOKEN}" > /root/.huggingface/token
        chmod 600 /root/.huggingface/token
    fi
    
    if [ -n "${WANDB_API_KEY-}" ]; then
        log "Configuring Weights & Biases..."
        mkdir -p /root/.netrc
        echo "machine api.wandb.ai" > /root/.netrc
        echo "login user" >> /root/.netrc
        echo "password ${WANDB_API_KEY}" >> /root/.netrc
        chmod 600 /root/.netrc
    fi
}

# Verify workspace structure
setup_workspace() {
    log "Setting up workspace structure..."
    mkdir -p /workspace/SimpleTuner/{config,datasets,output,cache}
    mkdir -p /workspace/StableSwarmUI/Models/Lora/flux
    mkdir -p /workspace/file-scripts
    chmod -R 777 /workspace
    chown -R root:root /workspace
}

# Main execution
log "Starting PyTorch240 container..."
log "Container Version: $CONTAINER_VERSION"

# Setup workspace and services
setup_workspace
start_service ssh
start_service nginx

# Setup components
setup_jupyter
setup_ml_tools

log "All services started. Available at:"
log "- Jupyter Lab: http://localhost:${JUPYTER_PORT}"
log "- SSH: ssh -p ${SSH_PORT} root@localhost"
log "- HTTP: http://localhost:80"

# Keep container running and monitor Jupyter
while true; do
    sleep 30
    if ! pgrep jupyter-lab > /dev/null; then
        log "Jupyter Lab process died - restarting..."
        setup_jupyter
    fi
done
