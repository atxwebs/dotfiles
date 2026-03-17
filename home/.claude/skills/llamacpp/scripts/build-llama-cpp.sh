#!/bin/bash
# Build llama.cpp with CUDA for RTX 4070 Laptop (sm_89)
# Fix: CMake was finding /usr/bin/nvcc (CUDA 11.5) instead of cuda-12.6

set -e
cd ~/Applications/llamacpp
rm -rf build

export PATH=/usr/local/cuda-12.6/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:${LD_LIBRARY_PATH:-}

# Force CMake to use CUDA 12.6 (not /usr/bin/nvcc which is 11.5)
# 89 = your RTX 4070; building only for your GPU = faster compile
cmake -B build \
  -DGGML_CUDA=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.6/bin/nvcc \
  -DCMAKE_CUDA_ARCHITECTURES=89

cmake --build build --config Release -j
echo "Done. Binaries in build/bin/"
