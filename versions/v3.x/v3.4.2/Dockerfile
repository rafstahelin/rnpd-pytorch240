# PyTorch240 Production Container v3.4.2
# Focus: Weights & Biases Integration
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
    # WANDB configuration
    WANDB_DIR=/workspace/.wandb \
    WANDB_CACHE_DIR=/workspace/.cache/wandb \
    WANDB_CONFIG_DIR=/workspace/.config/wandb \
    # HF configuration (from v3.4.1)
    HF_HOME=/workspace/.cache/huggingface \
    # Version tracking
    CONTAINER_VERSION=v3.4.2

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
    htop \
    dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache/*

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    echo "root:1234" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    # Generate SSH host keys
    ssh-keygen -A

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
    # WANDB specific packages
    wandb==0.16.* \
    pandas==2.2.* \
    matplotlib==3.8.* \
    seaborn==0.13.* \
    # HF packages (from v3.4.1)
    huggingface-hub==0.20.* \
    transformers==4.37.* \
    datasets==2.17.* \
    && rm -rf /root/.cache/pip

# Setup workspace structure
RUN mkdir -p /workspace/SimpleTuner/{config,datasets,output} \
    /workspace/StableSwarmUI/Models/Lora/flux \
    /workspace/file-scripts \
    /workspace/.wandb \
    /workspace/.cache/wandb \
    /workspace/.config/wandb \
    /workspace/.cache/huggingface \
    && chmod -R 777 /workspace \
    && chown -R root:root /workspace

# Copy scripts
COPY versions/v3.x/v3.4.2/start.sh /start.sh
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
