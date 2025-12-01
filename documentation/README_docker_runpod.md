# run-ai-toolkit

## Synopsis

A streamlined setup for running **Ostris AI Toolkit** for training models and lora's for ComfyUI

- UI interface
- Authentication credentials can be set via secrets for:  
  - **Code server** authentication.
  - **Hugging Face** token for model access.
  - **ai-toolkit UI** password

## Deployment on RunPod.io

[**👉 AI Toolkit**](https://console.runpod.io/deploy?template=3cmazei34j&ref=se4tkc5o)

### Hardware provisioning recommendation

- GPU: RTX A5000, RTX 4090, RTX 4000 Ada.
- Pod volume: 50Gb (models)
- Workspace: 30 Gb (depending on dataset and output)

## Setup

| Component | Version              |
|-----------|----------------------|
| OS        | `Ubuntu 22.04 x86_64`|
| Python    | `3.11.x`             |
| PyTorch   | `2.9.1`              |
| CUDA      | `12.8.x`             |
| Triton    | `3.4.x`              |
| CodeServer | Latest |

## Installed Attentions

### Wheels

| Package        | Version  |
|----------------|----------|
| flash_attn     | 2.8.3    |
| sageattention  | 2.2.0    |

### Build for

| Processor | Compute Capability | SM |
|------------|-----------------|-----------|
| A40  | 8.6 | sm_86 |
| L40S | 8.9 | sm_89 |

## Environment Variables  

## **Authentication Tokens**  

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
| **Tensorboard** | `6006` (HTTP) |
| **SSH/SCP**     | `22`   (TCP)  |

