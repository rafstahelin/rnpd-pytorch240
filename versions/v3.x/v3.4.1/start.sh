#!/bin/bash
# PyTorch240 v3.4.1 Startup Script
# Focus: HuggingFace Integration

# Create log directory
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

# Configure HuggingFace token if provided
setup_huggingface() {
    if [ -n "${HF_TOKEN-}" ]; then
        log "Configuring HuggingFace..."
        mkdir -p ~/.huggingface
        echo "${HF_TOKEN}" > ~/.huggingface/token
        chmod 600 ~/.huggingface/token
        
        # Test HF token
        if python3 -c "from huggingface_hub import HfApi; api = HfApi(); api.token_status('${HF_TOKEN}')"; then
            log "HuggingFace token configured successfully"
        else
            log "Warning: HuggingFace token validation failed"
        fi
    else
        log "HF_TOKEN not set - skipping HuggingFace setup"
    fi
}

# Start services
log "Starting services..."
service ssh start
service nginx start

# Setup HuggingFace
setup_huggingface

# Configure and start Jupyter
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

# Start Jupyter Lab
cd /workspace
jupyter lab --no-browser &
JUPYTER_PID=$!

log "Container v3.4.1 started successfully"
log "Available services:"
log "- Jupyter Lab: http://localhost:${JUPYTER_PORT}"
log "- SSH: ssh -p ${SSH_PORT} root@localhost"
log "- HTTP: http://localhost:80"

# Keep container running
wait $JUPYTER_PID
