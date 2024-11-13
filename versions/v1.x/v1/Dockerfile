# RAF RunPod PyTorch Template - Debug Version
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Minimal environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    JUPYTER_PORT=8888 \
    PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Essential system dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /workspace \
    && chmod 777 /workspace

# Minimal Python packages
RUN pip install --no-cache-dir \
    jupyterlab==4.1.* \
    notebook==7.1.* \
    ipython==8.12.* \
    numpy==1.26.*

# Copy and prepare startup script
COPY start-debug.sh /
RUN chmod +x /start-debug.sh

EXPOSE 8888
WORKDIR /workspace

# Simple healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8888/api || exit 1

ENTRYPOINT ["/bin/bash", "/start-debug.sh"]
