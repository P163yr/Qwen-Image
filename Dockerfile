FROM runpod/worker-comfyui:5.5.1-base

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install -U comfy-cli

# Pin ComfyUI rather than using latest
RUN comfy --workspace /comfyui update comfy --version 0.38.2

# Qwen Image 2.1 PDD 4-step node
RUN git clone --depth 1 \
    https://github.com/T8mars/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8 \
    /comfyui/custom_nodes/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8

RUN if [ -f /comfyui/custom_nodes/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8/requirements.txt ]; then \
      pip install --no-cache-dir \
      -r /comfyui/custom_nodes/Comfyui-Qwen-Image-2.1-Fun-Acc-LoRAs-T8/requirements.txt; \
    fi

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
