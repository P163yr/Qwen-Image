FROM runpod/worker-comfyui:5.5.1-base

USER root

# Basic tools needed for cloning the custom node
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Upgrade comfy-cli
RUN pip install --no-cache-dir -U comfy-cli

# Update ComfyUI
RUN comfy --workspace /comfyui update comfy --version latest

# Install Qwen Image 2.1 Fun-Acc PDD 4-Step custom node
RUN git clone --depth 1 \
    https://github.com/T8mars/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8 \
    /comfyui/custom_nodes/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8

# Install node requirements only if the repo has any
RUN if [ -f /comfyui/custom_nodes/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8/requirements.txt ]; then \
      pip install --no-cache-dir \
      -r /comfyui/custom_nodes/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8/requirements.txt; \
    fi

# Point ComfyUI at your network-volume models
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

WORKDIR /comfyui
