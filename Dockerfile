FROM runpod/worker-comfyui:5.10.0-base

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /comfyui

# ---------------------------------------------------------
# ComfyUI 0.38.2
# ---------------------------------------------------------

RUN git fetch --all --tags && \
    git checkout v0.38.2

# ---------------------------------------------------------
# Install ComfyUI 0.38.2 requirements
# ---------------------------------------------------------

RUN uv pip install -r /comfyui/requirements.txt

# ---------------------------------------------------------
# Force the native Linux x86_64 comfy-aimdo wheel.
#
# The generic py3-none-any wheel can lead to:
# ModuleNotFoundError: comfy_aimdo.storage
# ---------------------------------------------------------

RUN uv pip uninstall comfy-aimdo || true

RUN wget -O /tmp/comfy_aimdo.whl \
    "https://files.pythonhosted.org/packages/5d/18/807dd84d80469c9620928429911b9ff04c699e8b47204423a8804ac3f09d/comfy_aimdo-0.5.5-cp39-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl" && \
    uv pip install /tmp/comfy_aimdo.whl && \
    rm -f /tmp/comfy_aimdo.whl

# ---------------------------------------------------------
# Keep compatible HF stack
# ---------------------------------------------------------

RUN uv pip install \
    "transformers>=4.50.3,<5" \
    "huggingface-hub<1.0"

# ---------------------------------------------------------
# ComfyUI Manager
# ---------------------------------------------------------

RUN rm -rf /comfyui/custom_nodes/ComfyUI-Manager && \
    git clone \
    https://github.com/Comfy-Org/ComfyUI-Manager.git \
    /comfyui/custom_nodes/ComfyUI-Manager

RUN if [ -f /comfyui/custom_nodes/ComfyUI-Manager/requirements.txt ]; then \
      uv pip install -r /comfyui/custom_nodes/ComfyUI-Manager/requirements.txt; \
    fi

# ---------------------------------------------------------
# IMPORTANT:
# Manager requirements may modify dependencies again,
# so force comfy-aimdo native wheel one final time.
# ---------------------------------------------------------

RUN uv pip uninstall comfy-aimdo || true

RUN wget -O /tmp/comfy_aimdo.whl \
    "https://files.pythonhosted.org/packages/5d/18/807dd84d80469c9620928429911b9ff04c699e8b47204423a8804ac3f09d/comfy_aimdo-0.5.5-cp39-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl" && \
    uv pip install /tmp/comfy_aimdo.whl && \
    rm -f /tmp/comfy_aimdo.whl

# ---------------------------------------------------------
# Verify aimdo BEFORE starting ComfyUI
# ---------------------------------------------------------

RUN python -c "\
import comfy_aimdo; \
import comfy_aimdo.storage; \
print('comfy_aimdo OK'); \
print('storage module OK')"

# ---------------------------------------------------------
# Network volume
# ---------------------------------------------------------

RUN mkdir -p /runpod-volume

# ---------------------------------------------------------
# Verify ComfyUI startup
# ---------------------------------------------------------

RUN cd /comfyui && \
    timeout 300 python main.py --quick-test-for-ci --cpu

# ---------------------------------------------------------
# Verify exact version
# ---------------------------------------------------------

RUN cd /comfyui && git describe --tags --always

WORKDIR /
