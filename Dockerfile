# Keep the known-working RunPod handler and ComfyUI installation layout.
# Deploy ONLY on a CUDA 13.0-capable host with NVIDIA driver r580 or newer.
FROM runpod/worker-comfyui:5.10.0-base

USER root
WORKDIR /comfyui

# The inherited start.sh reads this variable (its default is DEBUG).
ENV COMFY_LOG_LEVEL=INFO

# Keep the same ComfyUI version as the working workflow.
RUN git fetch --depth 1 origin tag v0.38.2 && \
    git checkout --detach v0.38.2

# Explicit +cu130 pins replace the base image's +cu128 builds.
# Install into the interpreter used by /start.sh, not /comfyui/.venv.
RUN uv pip install --python /opt/venv/bin/python \
    "torch==2.11.0+cu130" \
    "torchvision==0.26.0+cu130" \
    "torchaudio==2.11.0+cu130" \
    --index-url https://download.pytorch.org/whl/cu130

# This version pins comfy-kitchen and comfy-aimdo itself.
RUN uv pip install --python /opt/venv/bin/python \
    -r /comfyui/requirements.txt

# Preserve both previously supported network-volume directory layouts.
# No model downloads, model moves, or Civitai credentials are required.
RUN printf '%s\n' \
    '' \
    'qwen_network_volume:' \
    '  base_path: /runpod-volume' \
    '  diffusion_models: |' \
    '    comfyui/models/diffusion_models' \
    '    models/diffusion_models' \
    '  text_encoders: |' \
    '    comfyui/models/text_encoders' \
    '    models/text_encoders' \
    '  vae: |' \
    '    comfyui/models/vae' \
    '    models/vae' \
    '  loras: |' \
    '    comfyui/models/loras' \
    '    models/loras' \
    >> /comfyui/extra_model_paths.yaml

# Build-time checks: package variant and CPU imports only.
# GPU/backend availability MUST be checked later on a running GPU worker.
RUN /opt/venv/bin/python -c \
    "import torch, torchvision, torchaudio, comfy_aimdo.storage; print('PyTorch:', torch.__version__, 'CUDA:', torch.version.cuda); assert torch.version.cuda == '13.0', 'Expected the cu130 PyTorch build'" && \
    timeout 300 /opt/venv/bin/python /comfyui/main.py \
    --cpu --quick-test-for-ci --verbose INFO

# Inherit /start.sh and the existing Serverless handler unchanged.
WORKDIR /
