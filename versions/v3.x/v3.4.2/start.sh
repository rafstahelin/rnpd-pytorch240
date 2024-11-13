#!/bin/bash
# PyTorch240 v3.4.2 Startup Script
# Focus: Weights & Biases Integration

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

# Start service with monitoring
start_service() {
    local service=$1
    log "Starting $service..."
    case "$service" in
        ssh)
            # Ensure SSH host keys exist
            if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
                log "Regenerating SSH host keys..."
                ssh-keygen -A
            fi
            /usr/sbin/sshd
            ;;
        nginx)
            service nginx start
            ;;
        *)
            service "$service" start
            ;;
    esac
    
    sleep 2
    
    case "$service" in
        ssh)
            if pgrep -f sshd > /dev/null; then
                log "SSH started successfully"
                return 0
            fi
            ;;
        *)
            if service "$service" status; then
                log "$service started successfully"
                return 0
            fi
            ;;
    esac
    
    log "Failed to start $service"
    return 1
}

# Setup WANDB configuration
setup_wandb() {
    # Extract actual key from environment variable
    local wandb_key="${WANDB_API_KEY#*=}"  # Remove everything before = if it exists
    
    if [ -n "${wandb_key}" ]; then
        log "Configuring Weights & Biases..."
        
        # Create WANDB directories if they don't exist
        mkdir -p "${WANDB_DIR}" "${WANDB_CACHE_DIR}" "${WANDB_CONFIG_DIR}"
        chmod -R 777 "${WANDB_DIR}" "${WANDB_CACHE_DIR}" "${WANDB_CONFIG_DIR}"
        
        # Export clean key for wandb
        export WANDB_API_KEY="${wandb_key}"
        
        # Try to login
        if python3 -c "import wandb; wandb.login()" >/dev/null 2>&1; then
            log "WANDB login successful"
            return 0
        else
            log "WANDB login failed"
            return 1
        fi
    else
        log "WANDB_API_KEY not set or empty - skipping WANDB setup"
        return 0
    fi
}

# Similarly for other variables that might have = added
setup_hf() {
    local hf_token="${HF_TOKEN#*=}"
    
    if [ -n "${hf_token}" ]; then
        log "Configuring Hugging Face..."
        mkdir -p ~/.huggingface
        echo "${hf_token}" > ~/.huggingface/token
        chmod 600 ~/.huggingface/token
        log "HuggingFace token configured"
    else
        log "HF_TOKEN not set - skipping HuggingFace setup"
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
        "/workspace/.wandb"
        "/workspace/.cache/wandb"
        "/workspace/.config/wandb"
        "/workspace/.cache/huggingface"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            chmod 777 "$dir"
        fi
    done
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

# Main execution
log "Starting PyTorch240 v3.4.2 container..."
log "Container Version: $CONTAINER_VERSION"

# Start core services
start_service ssh
start_service nginx

# Setup components
verify_workspace
setup_jupyter
setup_wandb
setup_hf

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
