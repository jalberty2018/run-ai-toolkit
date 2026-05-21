# run-ai-toolkit

## Synopsis

A streamlined setup for running **Ostris AI Toolkit** for training models and lora's for ComfyUI

- UI interface
- Authentication credentials can be set via secrets for:  
  - **Code server** authentication.
  - **Hugging Face** token for model access.
  - **ai-toolkit UI** password

## Hardware provisioning recommendation

### ZiB and Flux-Klein 9B

- GPU: RTX A5000, RTX 4090.
- Pod volume: 40Gb  (model)
- Workspace: 20 Gb  (dataset and output)

## Setup

| Component | Version              |
|-----------|----------------------|
| OS        | `Ubuntu 22.04 x86_64`|
| Python    | `3.11.x`             |
| PyTorch   | `2.9.1`              |
| CUDA      | `12.8.x`             |
| Triton    | `3.4.x`              |
| CodeServer | Latest |
| ai-toolkit   | Latest |

## Installed Attentions

### Wheels

| Package        | Version  |
|----------------|----------|
| flash_attn     | 2.8.3    |
| sageattention  | 2.2.0    |

### Build for

| Processor example | Compute Capability | SM |
|------------|-----------------|-----------|
| RTX A5000  | 8.6 | sm_86 |
| RTX 4090 | 8.9 | sm_89 |

## Environment Variables  

### **Authentication Tokens**  

| Token        | Environment Variable |
|--------------|----------------------|
| Huggingface  | `HF_TOKEN`           |
| Code Server  | `PASSWORD`           |
| ai-toolkit   | `AI_TOOLKIT_AUTH`    |

## Connection options 

### Services

| Service         | Port          |
|-----------------|---------------| 
| **ai-toolkit UI** | `8675` (HTTP)|
| **Code Server** | `9000` (HTTP) |
| **SSH/SCP**     | `22`   (TCP)  |

