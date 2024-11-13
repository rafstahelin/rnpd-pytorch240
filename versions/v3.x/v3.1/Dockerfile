# PyTorch240 Debug Container v3.1
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    JUPYTER_PASSWORD=1234 \
    JUPYTER_PORT=8888 \
    SSH_PORT=22 \
    PYTHONPATH=/workspace/file-scripts \
    GITHUB_REPO=https://github.com/rafstahelin/file-scripts.git

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    nginx \
    openssh-server \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    bash \
    xterm \
    cron \
    htop \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Terminal setup
RUN mkdir -p /var/run/jupyter && \
    chmod 777 /var/run/jupyter

# Setup SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:1234' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    ssh-keygen -A

# Setup nginx
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        proxy_pass http://localhost:8888; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_http_version 1.1; \
    } \
}' > /etc/nginx/sites-available/default

# Install Python packages
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook \
    jupyter_server \
    terminado \
    ipython \
    numpy \
    rich \
    && rm -rf /root/.cache/pip

# Setup workspace structure
RUN mkdir -p /workspace/{file-scripts,SimpleTuner,StableSwarmUI} && \
    chmod -R 777 /workspace

# Copy startup script
COPY start-debug.sh /start-debug.sh
RUN dos2unix /start-debug.sh && \
    chmod +x /start-debug.sh

# Expose ports
EXPOSE $JUPYTER_PORT $SSH_PORT 80

# Set working directory
WORKDIR /workspace

# Start services
CMD ["/start-debug.sh"]
