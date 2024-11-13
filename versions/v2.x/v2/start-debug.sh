#!/bin/bash
# Debug startup script with minimal configuration

# Simple error handling
set -e

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Print startup information
log_message "Starting debug container..."
log_message "Python version: $(python --version)"
log_message "Pip version: $(pip --version)"
log_message "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"

# Generate Jupyter config
jupyter lab --generate-config

# Set password using Python directly
python -c "
from jupyter_server.auth import passwd
password = '${JUPYTER_PASSWORD:-runpod}'  # Use env variable or default to 'runpod'
with open('/root/.jupyter/jupyter_lab_config.py', 'w') as f:
    f.write(f\"\"\"
c.ServerApp.allow_root = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.password = '{passwd(password)}'
c.ServerApp.allow_origin = '*'
c.ServerApp.root_dir = '/workspace'
c.ServerApp.token = ''  # Disable token authentication
c.ServerApp.terminado_settings = {{'shell_command': ['/bin/bash']}}
\"\"\")
"

# Start Jupyter Lab with detailed logging
log_message "Starting Jupyter Lab..."
exec jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root 2>&1
