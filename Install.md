# Installation Guide

## Quick Installation (Recommended)

We provide a complete installation script that sets up everything automatically:

```bash
bash install.sh
```

This script will:
1. Create a conda environment named `foundationpose` (Python 3.9)
2. Install all FoundationPose dependencies (Eigen3, Kaolin, PyTorch3D, NVDiffRast)
3. Install FoundationPose-plus-plus additional components (SAM-HQ, Qwen2-VL, Cutie)
4. Build all extensions
5. Download all model weights

After installation, activate the environment and start using the project:

```bash
conda activate foundationpose
cd FoundationPose
python run_demo.py
```

## Manual Installation

If you prefer to install step by step:

### Step 1: Create Conda Environment

```bash
conda create -n foundationpose python=3.9
conda activate foundationpose
```

### Step 2: Install FoundationPose Dependencies

```bash
# Install Eigen3
conda install conda-forge::eigen=3.4.0

# Install base dependencies
cd FoundationPose
pip install -r requirements.txt

# Install NVDiffRast
pip install git+https://github.com/NVlabs/nvdiffrast.git

# Install Kaolin
pip install kaolin==0.15.0 -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.0.0_cu118.html

# Install PyTorch3D
pip install pytorch3d -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py39_cu118_pyt200/download.html
```

### Step 3: Build Extensions

```bash
cd FoundationPose
CMAKE_PREFIX_PATH=$CONDA_PREFIX/lib/python3.9/site-packages/pybind11/share/cmake/pybind11 bash build_all_conda.sh
```

### Step 4: Install FoundationPose-plus-plus Components

```bash
cd ..
pip install hydra-core fastapi uvicorn
pip install segment-anything-hq transformers accelerate qwen-vl-utils

# Install SAM-HQ
cd sam-hq
pip install -e .
cd ..

# Install Cutie
cd Cutie
pip install -e .
cd ..
```

### Step 5: Download Weights

Download all required weights manually or use the following commands:

```bash
# Install download tools
pip install gdown huggingface_hub

# Download FoundationPose weights
cd FoundationPose/weights
gdown --folder https://drive.google.com/drive/folders/1DFezOAD0oD1BblsXVxqDsl8fj0qzB82i
cd ../..

# Download Qwen2-VL weights
cd Qwen2-VL/weights
huggingface-cli download Qwen/Qwen2-VL-7B-Instruct --local-dir .
cd ../..

# Download Sam-HQ weights
cd sam-hq/pretrained_checkpoints
gdown https://drive.google.com/uc?id=1Uk17tDKX1YAKas5knI4y9ZJCo0lRVL0G
cd ../..

# Download Cutie models
cd Cutie
python cutie/utils/download_models.py
cd ..
```

## Verify Installation

Check if all weights are downloaded:

```bash
du -sh FoundationPose/weights/ Qwen2-VL/weights/ sam-hq/pretrained_checkpoints/ Cutie/weights/
```

Expected output:
- FoundationPose/weights/: ~247MB
- Qwen2-VL/weights/: ~16GB
- sam-hq/pretrained_checkpoints/: ~1.2GB
- Cutie/weights/: ~173MB

## Troubleshooting

If you encounter issues:

1. **Build errors**: Make sure CMake, gcc, and Python development headers are installed
2. **Weight download failures**: Check internet connection or download manually
3. **CUDA compatibility**: The script automatically detects and installs appropriate CUDA versions
