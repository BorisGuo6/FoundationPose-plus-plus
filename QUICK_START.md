# Quick Start Guide

## Installation

Run the unified installation script:

```bash
bash install.sh
```

This will create a conda environment `foundationpose` and install all dependencies.

## Usage

Activate the environment:

```bash
conda activate foundationpose
```

### Run FoundationPose Demo

```bash
cd FoundationPose
python run_demo.py
```

### Run FoundationPose-plus-plus Demo

See README.md for detailed instructions on running the tracking demo with lego_20fps data.

## Verify Installation

Check if all modules are working:

```bash
python -c "import torch, pytorch3d, transformers; from FoundationPose.Utils import *; print('All modules OK!')"
```

## Environment Info

- Python: 3.9
- PyTorch: 2.0.0+cu118
- PyTorch3D: 0.7.3
- Transformers: 4.40.0

