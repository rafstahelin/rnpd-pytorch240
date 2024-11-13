# PyTorch240 Debug Container v2.2
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    JUPYTER_PASSWORD=1234 \
    JUPYTER_PORT=8888 \
    SSH_PORT=22

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
    && rm -rf /var/lib/apt/lists/* \
    # Terminal setup
    && mkdir -p /var/run/jupyter \
    && chmod 777 /var/run/jupyter

# Setup SSH
RUN mkdir /var/run/sshd && \
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

# Install JupyterLab with terminal support
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook \
    jupyter_server \
    terminado \
    ipython \
    numpy \
    black \
    pylint

# Setup workspace
RUN mkdir -p /workspace && \
    chmod 777 /workspace

# Copy startup script
COPY start-debug.sh /start-debug.sh
RUN chmod +x /start-debug.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888 || exit 1

# Expose ports
EXPOSE $JUPYTER_PORT $SSH_PORT 80

# Set working directory
WORKDIR /workspace

# Start services
CMD ["/start-debug.sh"]
