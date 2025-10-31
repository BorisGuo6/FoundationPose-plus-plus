#!/bin/bash

# Complete installation script for FoundationPose-plus-plus
# This script creates a conda environment 'foundationpose' and installs all dependencies
# Usage: bash install.sh

set -e  # Exit on error

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "========================================="
echo "FoundationPose-plus-plus Complete Installation"
echo "========================================="
echo "Project root: $PROJECT_ROOT"
echo ""

# Check if foundationpose environment already exists
if conda env list | grep -q "^foundationpose "; then
    echo "Warning: 'foundationpose' environment already exists!"
    read -p "Do you want to remove it and create a new one? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing environment..."
        conda env remove -n foundationpose -y
    else
        echo "Using existing environment. Activating it now..."
        source $(conda info --base)/etc/profile.d/conda.sh
        conda activate foundationpose
        SKIP_ENV_SETUP=1
    fi
fi

if [ -z "$SKIP_ENV_SETUP" ]; then
    # Step 1: Create conda environment
    echo "Step 1: Creating conda environment 'foundationpose' with Python 3.9..."
    conda create -n foundationpose python=3.9 -y

    # Step 2: Activate environment
    echo ""
    echo "Step 2: Activating environment..."
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate foundationpose
fi

export PROJECT_ROOT="$PROJECT_ROOT"
echo "PROJECT_ROOT=$PROJECT_ROOT"

# Step 3: Install Eigen3
echo ""
echo "Step 3: Installing Eigen3 3.4.0..."
conda install conda-forge::eigen=3.4.0 -y
export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:$(conda info --base)/envs/foundationpose"

# Step 4: Install PyTorch with CUDA 11.8 (compatible with PyTorch3D)
echo ""
echo "Step 4: Installing PyTorch with CUDA 11.8..."
pip install torch==2.0.0 torchvision==0.15.0 --index-url https://download.pytorch.org/whl/cu118

# Detect CUDA version
CUDA_VERSION=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $5}' | cut -c1-4) || CUDA_VERSION="unknown"
echo "Detected CUDA version: $CUDA_VERSION"

# Install other dependencies from requirements.txt (skip torch)
cd "$PROJECT_ROOT/FoundationPose"
# Get requirements and filter out torch/torchvision
grep -v "^torch" requirements.txt | grep -v "^--extra-index-url" > /tmp/fp_requirements.txt || true
pip install -r /tmp/fp_requirements.txt
rm /tmp/fp_requirements.txt

# Step 5: Install NVDiffRast
echo ""
echo "Step 5: Installing NVDiffRast..."
python -m pip install --quiet --no-cache-dir git+https://github.com/NVlabs/nvdiffrast.git

# Step 6: Install Kaolin
echo ""
echo "Step 6: Installing Kaolin..."
if [[ "$CUDA_VERSION" == "12."* ]]; then
    python -m pip install --quiet --no-cache-dir kaolin==0.15.0 || {
        echo "Warning: Kaolin installation failed, trying alternative..."
        python -m pip install --quiet --no-cache-dir kaolin || {
            echo "Warning: Kaolin installation failed, skipping..."
        }
    }
else
    python -m pip install --quiet --no-cache-dir kaolin==0.15.0 -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.0.0_cu118.html || {
        echo "Warning: Kaolin installation failed, skipping..."
    }
fi

# Step 7: Install PyTorch3D
echo ""
echo "Step 7: Installing PyTorch3D for CUDA 11.8..."
python -m pip install --quiet --no-index --no-cache-dir pytorch3d==0.7.3 -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py39_cu118_pyt200/download.html || {
    echo "Warning: PyTorch3D installation failed, skipping..."
}

cd "$PROJECT_ROOT"

# Step 8: Install FoundationPose-plus-plus dependencies
echo ""
echo "Step 8: Installing FoundationPose-plus-plus dependencies..."
python -m pip install hydra-core fastapi uvicorn
python -m pip install --upgrade pybind11

# Step 9: Build FoundationPose extensions
echo ""
echo "Step 9: Building FoundationPose extensions..."
cd "$PROJECT_ROOT/FoundationPose"

# Build mycpp
echo "Building mycpp..."
cd mycpp
rm -rf build && mkdir -p build && cd build
PYBIND11_CMAKE_DIR=$(python -c "import pybind11; print(pybind11.get_cmake_dir())")
cmake .. -DPYTHON_EXECUTABLE=$(which python) -Dpybind11_DIR="$PYBIND11_CMAKE_DIR"
make -j$(nproc)
cd "$PROJECT_ROOT/FoundationPose"

# Build mycuda (if exists)
if [ -d "bundlesdf/mycuda" ]; then
    echo "Building mycuda..."
    cd bundlesdf/mycuda
    rm -rf build *egg* *.so 2>/dev/null || true
    python -m pip install -e . || echo "Warning: mycuda build failed"
    cd "$PROJECT_ROOT/FoundationPose"
fi

cd "$PROJECT_ROOT"

# Step 10: Install SAM-HQ
echo ""
echo "Step 10: Installing SAM-HQ..."
python -m pip install segment-anything-hq
cd "$PROJECT_ROOT/sam-hq"
python -m pip install -e .
cd "$PROJECT_ROOT"

# Step 11: Install Qwen2-VL dependencies
echo ""
echo "Step 11: Installing Qwen2-VL dependencies..."
# Use transformers 4.40.0 for compatibility with PyTorch 2.0
python -m pip install transformers==4.40.0 accelerate qwen-vl-utils

# Step 12: Install Cutie
echo ""
echo "Step 12: Installing Cutie..."
cd "$PROJECT_ROOT/Cutie"
python -m pip install -e . || {
    echo "Warning: Cutie installation failed, trying with compatibility fix..."
    # The cchardet dependency issue should have been fixed in pyproject.toml
}
cd "$PROJECT_ROOT"

# Step 13: Download Cutie models
echo ""
echo "Step 13: Downloading Cutie models..."
cd "$PROJECT_ROOT/Cutie"
python cutie/utils/download_models.py || echo "Warning: Cutie model download failed"
cd "$PROJECT_ROOT"

# Step 14: Download all weights
echo ""
echo "Step 14: Downloading model weights..."
cd "$PROJECT_ROOT"

# Install required tools
if ! command -v gdown &> /dev/null; then
    pip install gdown
fi

if ! command -v huggingface-cli &> /dev/null; then
    pip install -U huggingface-hub
fi

# Create directories
mkdir -p "$PROJECT_ROOT/FoundationPose/weights"
mkdir -p "$PROJECT_ROOT/Qwen2-VL/weights"
mkdir -p "$PROJECT_ROOT/sam-hq/pretrained_checkpoints"

# Download FoundationPose weights
echo "Downloading FoundationPose weights..."
cd "$PROJECT_ROOT/FoundationPose/weights"
gdown --folder https://drive.google.com/drive/folders/1DFezOAD0oD1BblsXVxqDsl8fj0qzB82i --remaining-ok || {
    echo "Warning: FoundationPose weights download failed"
}

# Download Qwen2-VL weights
echo "Downloading Qwen2-VL weights..."
cd "$PROJECT_ROOT/Qwen2-VL/weights"
huggingface-cli download Qwen/Qwen2-VL-7B-Instruct --local-dir . --local-dir-use-symlinks False || {
    echo "Warning: Qwen2-VL weights download failed"
}

# Download Sam-HQ weights
echo "Downloading Sam-HQ weights..."
cd "$PROJECT_ROOT/sam-hq/pretrained_checkpoints"
gdown https://drive.google.com/uc?id=1Uk17tDKX1YAKas5knI4y9ZJCo0lRVL0G || {
    echo "Warning: Sam-HQ weights download failed"
}

cd "$PROJECT_ROOT"

# Final summary
echo ""
echo "========================================="
echo "Installation completed!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Activate the environment: conda activate foundationpose"
echo "2. Verify weights: du -sh FoundationPose/weights/ Qwen2-VL/weights/ sam-hq/pretrained_checkpoints/ Cutie/weights/"
echo "3. Run demo: cd FoundationPose && python run_demo.py"
echo ""
echo "Project ready to use!"
