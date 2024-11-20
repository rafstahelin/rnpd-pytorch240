#!/bin/bash
version="4.0.0"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

setup_password() {
    if [ -n "${JUPYTER_PASSWORD}" ]; then
        log "Setting up Jupyter password..."
        jupyter notebook password <<EOF
${JUPYTER_PASSWORD}
${JUPYTER_PASSWORD}
EOF
    fi
}

setup_rclone() {
    log "Starting rclone setup..."
    
    WORKSPACE_CONFIG="/workspace/.config/rclone/rclone.conf"
    ROOT_CONFIG="/root/.config/rclone/rclone.conf"
    
    mkdir -p "$(dirname $ROOT_CONFIG)"
    chmod 700 "$(dirname $ROOT_CONFIG)"
    
    if [ -f "$WORKSPACE_CONFIG" ]; then
        cp "$WORKSPACE_CONFIG" "$ROOT_CONFIG"
        chmod 600 "$ROOT_CONFIG"
        log "✓ Rclone configuration loaded"
        return 0
    else
        log "! No rclone config found - skipping"
        return 0
    fi
}

setup_huggingface() {
    if [ -n "${HF_TOKEN}" ]; then
        log "Configuring HuggingFace token..."
        mkdir -p ${HF_HOME}
        echo "${HF_TOKEN}" > ${HF_HOME}/token
        chmod 600 ${HF_HOME}/token
        log "✓ HuggingFace token configured"
    fi
}

start_services() {
    log "Starting services..."
    service ssh start
    service nginx start
}

setup_workspace() {
    log "Setting up workspace..."
    
    if [ ! -d "$WORKSPACE_PATH" ]; then
        mkdir -p $WORKSPACE_PATH
        chmod 777 $WORKSPACE_PATH
    fi
    
    cd $WORKSPACE_PATH
}

main() {
    log "Starting container initialization..."
    
    setup_workspace
    setup_password
    setup_rclone
    setup_huggingface
    start_services
    
    log "✓ Container initialization complete"
    log "Starting Jupyter Lab..."
    
    jupyter lab --ip=0.0.0.0 --port=$JUPYTER_PORT --allow-root
}

main
