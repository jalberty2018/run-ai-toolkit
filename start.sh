#!/bin/bash

echo "ℹ️ Pod run-ai-toolkit started"
echo "ℹ️ Wait until the message 🎉 Provisioning done, ready to train AI models 🎉. is displayed"

# Enable SSH if PUBLIC_KEY is set
if [[ -n "$PUBLIC_KEY" ]]; then
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    service ssh start
    echo "✅ [SSH enabled]"
fi

# Export env variables
if [[ -n "${RUNPOD_GPU_COUNT:-}" ]]; then
   echo "ℹ️ Exporting runpod.io environment variables..."
   printenv | grep -E '^RUNPOD_|^PATH=|^_=' \
     | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment

   echo 'source /etc/rp_environment' >> ~/.bashrc
fi

# Move files to workspace
for script in readme-on-workspace.sh docs-on-workspace.sh; do
    if [ -f "/$script" ]; then
        echo "Executing $script..."
        "/$script"
    else
        echo "⚠️ Skipping $script (not found)"
    fi
done

# Create workspace directories if they don’t exist
mkdir -p /workspace/output
mkdir -p /workspace/output/logs_tensorboard
mkdir -p /workspace/datasets

# GPU detection
echo "ℹ️ Testing GPU/CUDA provisioning"

# GPU detection Runpod.io
HAS_GPU_RUNPOD=0
if [[ -n "${RUNPOD_GPU_COUNT:-}" && "${RUNPOD_GPU_COUNT:-0}" -gt 0 ]]; then
  HAS_GPU_RUNPOD=1
  echo "✅ [GPU DETECTED] Found via RUNPOD_GPU_COUNT=${RUNPOD_GPU_COUNT}"
else
  echo "⚠️ [NO GPU] No Runpod.io GPU detected."
fi  

# GPU detection nvidia-smi
HAS_GPU=0
if command -v nvidia-smi >/dev/null 2>&1; then
  if nvidia-smi >/dev/null 2>&1; then
    HAS_GPU=1
    GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader | xargs | sed 's/,/, /g')
    echo "✅ [GPU DETECTED] Found via nvidia-smi → Model(s): ${GPU_MODEL}"
  else
    echo "⚠️ [NO GPU] nvidia-smi found but failed to run (driver or permission issue)"
  fi
else
  echo "⚠️ [NO GPU] No GPU found via nvidia-smi"
fi

# Start code-server (HTTP port 9000) 
if [[ "$HAS_GPU" -eq 1 || "$HAS_GPU_RUNPOD" -eq 1 ]]; then    
    echo "✅ Code-Server service starting"
	
    if [[ -n "$PASSWORD" ]]; then
        code-server /workspace --auth password --disable-update-check --disable-telemetry --host 0.0.0.0 --bind-addr 0.0.0.0:9000 &
    else
        echo "⚠️ PASSWORD is not set as an environment variable use password from /root/.config/code-server/config.yaml"
        code-server /workspace --disable-telemetry --disable-update-check --host 0.0.0.0 --bind-addr 0.0.0.0:9000 &
    fi
	
    echo "🎉 code-server service started"
else
    echo "⚠️ WARNING: No GPU available, Code Server not started to limit memory use"
fi

sleep 2

# Python, Torch CUDA check
HAS_CUDA=0
if command -v python >/dev/null 2>&1; then
  if python - << 'PY' >/dev/null 2>&1
import sys
try:
    import torch
    sys.exit(0 if torch.cuda.is_available() else 1)
except Exception:
    sys.exit(1)
PY
  then
    HAS_CUDA=1
  fi
else
  echo "⚠️ Python not found – assuming no CUDA"
fi

if [[ "$HAS_CUDA" -eq 1 ]]; then  	
    # Start TensorBoard on port 6006
	echo "✅ Starting Tensorboard service --logdir /workspace/output/logs_tensorboard"
    tensorboard --logdir /workspace/output/logs_tensorboard --host 0.0.0.0 &
	sleep 5
else
    echo "❌ ERROR: PyTorch CUDA driver mismatch or unavailable, tensorboard not started"
fi

if [[ "$HAS_CUDA" -eq 1 ]]; then    	
	# Start AI-toolkit interface 
    echo "✅ Starting ai-toolkit UI interface"
    if [[ -z "${AI_TOOLKIT_AUTH:-}" ]]; then           
        echo "⚠️ AI_TOOLKIT_AUTH is not set, ai-toolkit UI is not password protected ⚠️"
    else
		echo "ℹ️ Password set with AI_TOOLKIT_AUTH"
	fi
	
	AI_TOOLKIT_VERSION=$(grep -oP '(?<=VERSION = ")[0-9\.]+' /ai-toolkit/version.py)
    echo "🔰 AI-Toolkit version: $AI_TOOLKIT_VERSION"
	
	cd /ai-toolkit/ui && npm run start &
	
	# Wait until ai-toolkit ui is ready
    MAX_TRIES=40
    COUNT=0
		
    until curl -s http://127.0.0.1:8675 > /dev/null; do
        COUNT=$((COUNT+1))

        if [[ $COUNT -ge $MAX_TRIES ]]; then
            echo "⚠️  WARNING: ai-toolkit is still not responding after $MAX_TRIES attempts (~1 min)."
            echo "⚠️  Continuing script anyway..."
            break
        fi

        echo "ℹ️ Waiting for ai-toolkit to come online... ($COUNT/$MAX_TRIES)"
        sleep 5
    done

    # Success message only when ComfyUI responded
    if curl -s http://127.0.0.1:8675 > /dev/null; then
        echo "🎉 ai-toolkit is online!"
    fi
	
    sleep 1	    
else
    echo "❌ ERROR: PyTorch CUDA driver mismatch or unavailable"
fi

# Environment
echo "ℹ️ Running environment"

python - <<'PY'
import platform

# Safe imports – don't explode if something is missing
try:
    import torch
except Exception as e:
    print(f"PyTorch import error: {e}")
    torch = None

try:
    import triton
except Exception:
    triton = None

try:
    import onnxruntime as ort
except Exception:
    ort = None

print(f"Python: {platform.python_version()}")

if torch is not None:
    print(f"PyTorch: {torch.__version__}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"  ↳ CUDA runtime: {torch.version.cuda}")
        print(f"  ↳ GPU(s): {[torch.cuda.get_device_name(i) for i in range(torch.cuda.device_count())]}")
        try:
            import torch.backends.cudnn as cudnn
            print(f"  ↳ cuDNN: {cudnn.version()}")
        except Exception:
            pass
    print("Torch build info:")
    try:
        torch.__config__.show()
    except Exception:
        pass
else:
    print("PyTorch: not available")
PY

if [[ "$HAS_CUDA" -eq 1 ]]; then 
    echo "🎉 Provisioning done, ready to train AI models 🎉"
    
    if [[ "$HAS_GPU_RUNPOD" -eq 1 ]]; then
        echo "ℹ️ Connect to to services as displayed it the runpod console."
    fi
	
	echo "ℹ️ ⚠️Important: Change directories in AI-Toolkit UI's settings to /workspace/output/⚠️"
	
else
    echo "ℹ️ Running error diagnosis"

    if [[ "$HAS_GPU_RUNPOD" -eq 0 ]]; then
        echo "⚠️ Pod started without a runpod.io GPU"
    fi

	echo "❌ Pytorch CUDA driver error/mismatch/not available"
    if [[ "$HAS_GPU_RUNPOD" -eq 1 ]]; then
        echo "⚠️ [SOLUTION] Deploy pod on another region ⚠️"
    fi
fi

# Keep the container running
echo "ℹ️ End script"

# Keep the container running
exec sleep infinity
