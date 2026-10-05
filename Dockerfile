# RunPod worker base
FROM runpod/worker-comfyui:5.10.0-base

USER root
WORKDIR /comfyui

# Update ComfyUI and install requirements into its runtime Python
RUN git fetch --depth 1 origin tag v0.38.2 && \
    git checkout --detach v0.38.2 && \
    uv pip install --python /opt/venv/bin/python -r /comfyui/requirements.txt

# Models already exist on the network volume.
# Support both directory layouts discussed earlier.
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

# Check the previously failing import, then test CPU startup
RUN /opt/venv/bin/python -c "import comfy_aimdo.storage" && \
    timeout 300 /opt/venv/bin/python /comfyui/main.py --cpu --quick-test-for-ci

# Keep the base image's existing startup command and handler
WORKDIR /
