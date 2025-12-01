# syntax=docker/dockerfile:1.7
FROM ls250824/pytorch-cuda-ubuntu-develop:08112025

# Set working directory
WORKDIR /

# Copy start script
COPY --chmod=755 start.sh onworkspace/docs-on-workspace.sh onworkspace/readme-on-workspace.sh /

# Copy supporting files
COPY --chmod=664 /documentation/README.md /README.md
COPY --chmod=644 docs/ /docs

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install nodejs
WORKDIR /tmp
RUN curl -sL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh && \
    apt-get update && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /

# ref https://en.wikipedia.org/wiki/CUDA
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0 10.0 12.0"

# Pin flash & sage & onnx
RUN printf "numpy<2\nonnxruntime==0\nflash_attn==2.8.3\nsageattention==2.2.0\n" > /constraints.txt

# Download wheels
RUN wget -q https://github.com/jalberty2018/run-pytorch-cuda-develop/releases/download/v1.3.1/flash_attn-2.8.3-cp311-cp311-linux_x86_64.whl && \
    wget -q https://github.com/jalberty2018/run-pytorch-cuda-develop/releases/download/v1.3.1/sageattention-2.2.0-cp311-cp311-linux_x86_64.whl

# Install and remove wheels
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --no-cache-dir --root-user-action ignore -c /constraints.txt \
      ./flash_attn-2.8.3-cp311-cp311-linux_x86_64.whl \
      ./sageattention-2.2.0-cp311-cp311-linux_x86_64.whl \
      "huggingface_hub[cli]" onnx tensorboard && \
    rm -f flash_attn-2.8.3-cp311-cp311-linux_x86_64.whl \
          sageattention-2.2.0-cp311-cp311-linux_x86_64.whl

# Clone ai-toolkit
WORKDIR /
RUN --mount=type=cache,target=/root/.cache/git \
    git clone https://github.com/ostris/ai-toolkit.git

# Install requirements
WORKDIR /ai-toolkit
RUN --mount=type=cache,target=/root/.cache/pip \
  python -m pip install --no-cache-dir --root-user-action ignore -c /constraints.txt \
      -r requirements.txt

# Build UI
WORKDIR /ai-toolkit/ui
RUN npm install && \
    npm run build && \
    npm run update_db

# Set working directory for runtime
WORKDIR /workspace

# Expose ports (assuming the application runs on port 3000)
EXPOSE 9000 6006 8675

# Labels
LABEL org.opencontainers.image.title="run-ai-toolkit" \
      org.opencontainers.image.description="Pytorch 2.9 CUDA 12.8 devel + Ubuntu 22.04 + Python + code-server + ai-toolkit" \
      org.opencontainers.image.source="https://hub.docker.com/r/ls250824/run-ai-toolkit" \
      org.opencontainers.image.licenses="MIT"

# Test
RUN python -c "import torch, torchvision, torchaudio, triton; \
print(f'Torch: {torch.__version__}\\nTorchvision: {torchvision.__version__}\\nTorchaudio: {torchaudio.__version__}\\nTriton: {triton.__version__}\\nCUDA available: {torch.cuda.is_available()}\\nCUDA version: {torch.version.cuda}')"

# Start the container
CMD ["/start.sh"]