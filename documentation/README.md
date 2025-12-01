# run-ai-toolkit

## Documentation

- [Resources](docs/ai-toolkit_resources.md)
- [Hardware Requirements](docs/ai-toolkit_hardware.md)
- [Image setup](docs/ai-toolkit_image_setup.md)
- [Environment variables](docs/ai-toolkit_configuration.md)

## 7z

### Add directory to encrypted archive

```bash
7z a -p -mhe=on output-training.7z /workspace/output/
```

### Extract directory from archive

```bash
7z x x.7z
```

## Split-Join

### Split

```bash
split -n 3 x.7z x_part
```

### Join files

```bash
cat x_part* > x.7z
```

## Bash commands

```bash
nvtop
htop
ncdu
tmux
tmux attach
unzip
nvcc
nano
vim
ncdu
```
