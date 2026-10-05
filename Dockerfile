FROM runpod/worker-comfyui:5.10.0-base

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1

# ---------------------------------------------------------
# Runtime tools
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Upgrade ComfyUI from the base image's 0.34.0
# to the required 0.38.2.
#
# The RunPod worker already uses /comfyui.
# ---------------------------------------------------------

WORKDIR /comfyui

RUN git fetch --all --tags && \
    git checkout v0.38.2

# ---------------------------------------------------------
# Install dependencies required by ComfyUI 0.38.2
#
# RunPod worker uses /opt/venv for runtime.
# ---------------------------------------------------------

RUN uv pip install \
    torch==2.11.0 \
    torchvision==0.26.0 \
    torchaudio==2.11.0 \
    --index-url https://download.pytorch.org/whl/cu128

RUN uv pip install -r /comfyui/requirements.txt

# Keep these below major-breaking versions.
RUN uv pip install \
    "transformers>=4.50.3,<5" \
    "huggingface-hub<1.0"

# ---------------------------------------------------------
# Optional: ComfyUI Manager
#
# Manager is not required for the Qwen workflow to execute,
# because your Qwen 2.1 nodes are core ComfyUI nodes.
#
# But install Manager if you want it available for debugging.
# ---------------------------------------------------------

RUN rm -rf /comfyui/custom_nodes/ComfyUI-Manager && \
    git clone \
    https://github.com/Comfy-Org/ComfyUI-Manager.git \
    /comfyui/custom_nodes/ComfyUI-Manager

# Install Manager requirements if present.
RUN if [ -f /comfyui/custom_nodes/ComfyUI-Manager/requirements.txt ]; then \
      uv pip install -r /comfyui/custom_nodes/ComfyUI-Manager/requirements.txt; \
    fi

# ---------------------------------------------------------
# Network Volume
#
# RunPod Serverless mounts the attached Network Volume:
#
# /runpod-volume
#
# Models should exist as:
#
# /runpod-volume/comfyui/models/diffusion_models/
# /runpod-volume/comfyui/models/text_encoders/
# /runpod-volume/comfyui/models/vae/
# /runpod-volume/comfyui/models/loras/
# ---------------------------------------------------------

RUN mkdir -p /runpod-volume

# ---------------------------------------------------------
# Build-time verification
#
# This checks that ComfyUI 0.38.2 can actually import
# successfully before RunPod deploys the image.
# ---------------------------------------------------------

RUN cd /comfyui && \
    timeout 300 python main.py --quick-test-for-ci --cpu

# ---------------------------------------------------------
# Version check
# ---------------------------------------------------------

RUN cd /comfyui && \
    git describe --tags --always

# ---------------------------------------------------------
# Keep the RunPod worker's existing serverless startup.
# DO NOT replace its CMD.
# ---------------------------------------------------------

WORKDIR /
