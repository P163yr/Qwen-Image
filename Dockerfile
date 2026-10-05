FROM runpod/worker-comfyui:5.11.0-base

USER root

# ---------------------------------------------------------
# Minimal runtime utilities
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# RunPod Serverless mounts the selected Network Volume here:
#
# /runpod-volume
#
# We expect the volume to contain:
#
# /runpod-volume/comfyui/models/
#   diffusion_models/
#   text_encoders/
#   vae/
#   loras/
#
# The official worker-comfyui image knows how to discover
# models from this directory structure.
# ---------------------------------------------------------

RUN mkdir -p /runpod-volume

# ---------------------------------------------------------
# Optional startup verification.
#
# We do NOT fail the Docker BUILD if the models aren't present,
# because the Network Volume is only mounted at runtime.
# ---------------------------------------------------------

RUN cat <<'EOF' > /verify_network_volume.sh
#!/bin/bash
set -e

echo "=========================================="
echo "RunPod Network Volume check"
echo "=========================================="

MODEL_ROOT="/runpod-volume/comfyui/models"

if [ ! -d "$MODEL_ROOT" ]; then
    echo "WARNING: Network Volume model directory not found:"
    echo "$MODEL_ROOT"
    echo
    echo "Make sure the RunPod Network Volume is attached to"
    echo "the Serverless endpoint."
    exit 0
fi

echo "Network Volume found."
echo

echo "--- diffusion_models ---"
ls -lh "$MODEL_ROOT/diffusion_models" 2>/dev/null || true

echo
echo "--- text_encoders ---"
ls -lh "$MODEL_ROOT/text_encoders" 2>/dev/null || true

echo
echo "--- vae ---"
ls -lh "$MODEL_ROOT/vae" 2>/dev/null || true

echo
echo "--- loras ---"
ls -lh "$MODEL_ROOT/loras" 2>/dev/null || true

echo
echo "=========================================="
echo "Qwen Image 2.1 expected files"
echo "=========================================="

for file in \
  "$MODEL_ROOT/diffusion_models/qwen_image_2.1_int8_convrot.safetensors" \
  "$MODEL_ROOT/text_encoders/qwen3vl_8b_int8_convrot.safetensors" \
  "$MODEL_ROOT/text_encoders/qwen3.5_9b_qwen_image_2.1_pe_i2i.int8_convrot.safetensors" \
  "$MODEL_ROOT/vae/qwen_image_2.1_vae_bf16.safetensors" \
  "$MODEL_ROOT/loras/Qwen2.1_Anime_consistency.safetensors"
do
    if [ -f "$file" ]; then
        echo "OK: $file"
    else
        echo "MISSING: $file"
    fi
done

echo "=========================================="
EOF

RUN chmod +x /verify_network_volume.sh

# ---------------------------------------------------------
# Do NOT put models or Civitai credentials in this image.
#
# Models are read from:
# /runpod-volume/comfyui/models/
#
# Keep the base image's default RunPod Serverless CMD /
# entrypoint intact.
# ---------------------------------------------------------

WORKDIR /
