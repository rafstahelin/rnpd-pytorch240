FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn8-runtime

LABEL maintainer="RAF"
LABEL version="4.0.0"
LABEL description="PyTorch 2.4.0 RunPod Template with HF and Rclone support"

ENV DEBIAN_FRONTEND=noninteractive \
    JUPYTER_PASSWORD=1234 \
    SSH_PORT=22 \
    JUPYTER_PORT=8888 \
    HTTP_PORT=80 \
    WORKSPACE_PATH=/workspace \
    HF_HOME=/workspace/.cache/huggingface

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ssh \
    nginx \
    rclone \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    jupyter \
    jupyterlab \
    numpy \
    pandas \
    huggingface_hub \
    transformers \
    wandb==0.15.* \
    && rm -rf /root/.cache/pip

# Setup SSH
RUN mkdir /var/run/sshd && \
    echo "root:1234" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Setup Jupyter
RUN jupyter lab --generate-config && \
    echo "c.ServerApp.token = ''" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py

# Setup nginx
COPY nginx.conf /etc/nginx/sites-available/default

# Create workspace directory
RUN mkdir -p ${WORKSPACE_PATH} && \
    chmod 777 ${WORKSPACE_PATH}

# Create HuggingFace cache directory
RUN mkdir -p ${HF_HOME} && \
    chmod 777 ${HF_HOME}

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR ${WORKSPACE_PATH}

EXPOSE ${JUPYTER_PORT} ${SSH_PORT} ${HTTP_PORT}

CMD ["/start.sh"]
