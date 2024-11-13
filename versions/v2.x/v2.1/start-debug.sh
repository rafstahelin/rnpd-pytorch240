#!/bin/bash

# Enable error handling
set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Start SSH
start_ssh() {
    log "Starting SSH service..."
    service ssh start
    if [ $? -eq 0 ]; then
        log "SSH service started successfully"
    else
        log "Error starting SSH service"
        exit 1
    fi
}

# Start Nginx
start_nginx() {
    log "Starting Nginx service..."
    service nginx start
    if [ $? -eq 0 ]; then
        log "Nginx service started successfully"
    else
        log "Error starting Nginx service"
        exit 1
    fi
}

# Verify CUDA
verify_cuda() {
    log "Verifying CUDA installation..."
    if python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"; then
        log "CUDA verification successful"
    else
        log "CUDA verification failed"
        exit 1
    fi
}

# Start Jupyter
start_jupyter() {
    log "Starting Jupyter Lab..."
    jupyter lab --generate-config
    echo "c.ServerApp.password = '$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${JUPYTER_PASSWORD}'))")'" >> ~/.jupyter/jupyter_lab_config.py
    echo "c.ServerApp.allow_root = True" >> ~/.jupyter/jupyter_lab_config.py
    echo "c.ServerApp.ip = '0.0.0.0'" >> ~/.jupyter/jupyter_lab_config.py
    echo "c.ServerApp.port = ${JUPYTER_PORT}" >> ~/.jupyter/jupyter_lab_config.py
    jupyter lab --no-browser &
    log "Jupyter Lab started"
}

# Main execution
log "Starting PyTorch240 v2.1 container services..."

start_ssh
start_nginx
verify_cuda
start_jupyter

log "All services started successfully"

# Keep container running
tail -f /dev/null
