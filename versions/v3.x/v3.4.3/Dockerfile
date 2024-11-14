# PyTorch240 Production Container v3.4.3
# Focus: Rclone Integration
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    # Service configuration
    JUPYTER_PASSWORD=1234 \
    JUPYTER_PORT=8888 \
    SSH_PORT=22 \
    # File-scripts configuration
    PYTHONPATH=/workspace/file-scripts \
    GITHUB_REPO=https://github.com/rafstahelin/file-scripts.git \
    GITHUB_BRANCH=main \
    # Workspace configuration
    WORKSPACE_PATH=/workspace \
    # Rclone configuration
    RCLONE_CONFIG_PATH=/root/.config/rclone/rclone.conf \
    # Version tracking
    CONTAINER_VERSION=v3.4.3

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
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache/*

# Install rclone
# Install rclone
# Install rclone
RUN curl https://rclone.org/install.sh | bash \
    && mkdir -p /root/.config/rclone \
    && rclone --version

# Setup service directories
RUN mkdir -p /var/run/{jupyter,sshd} /var/log && \
    chmod 777 /var/run/jupyter && \
    touch /var/log/rclone.log && \
    chmod 666 /var/log/rclone.log

# Configure SSH
RUN echo "root:1234" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    ssh-keygen -A

# Configure nginx
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    client_max_body_size 100M; \
    location / { \
        proxy_pass http://localhost:8888; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_http_version 1.1; \
        proxy_buffering off; \
        proxy_read_timeout 86400; \
    } \
}' > /etc/nginx/sites-available/default

# Install Python packages
RUN pip install --no-cache-dir \
    jupyterlab==4.1.* \
    notebook==7.1.* \
    jupyter_server==2.12.* \
    terminado==0.18.* \
    ipython==8.22.* \
    numpy==1.26.* \
    rich==13.7.* \
    black==24.2.* \
    pylint==3.1.* \
    pyyaml==6.0.* \
    && rm -rf /root/.cache/pip

# Setup workspace structure
RUN mkdir -p /workspace/SimpleTuner/{config,datasets,output} && \
    mkdir -p /workspace/StableSwarmUI/Models/Lora/flux && \
    mkdir -p /workspace/file-scripts && \
    chmod -R 777 /workspace && \
    chown -R root:root /workspace

# Copy start script
COPY start.sh /start.sh
RUN dos2unix /start.sh && chmod +x /start.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:${JUPYTER_PORT} || exit 1

# Expose ports
EXPOSE $JUPYTER_PORT $SSH_PORT 80

# Set working directory
WORKDIR /workspace

# Start services
CMD ["/start.sh"]
