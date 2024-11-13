# PyTorch240 Debug Container v2.1
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
    && rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN mkdir /var/run/sshd && \
    echo 'root:1234' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Setup nginx
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        proxy_pass http://localhost:8888; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
    } \
}' > /etc/nginx/sites-available/default

# Setup Python environment
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
    jupyterlab \
    notebook \
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
