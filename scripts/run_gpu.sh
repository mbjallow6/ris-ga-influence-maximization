#!/usr/bin/env bash

# run_gpu.sh
# Runs the RIS+GA framework using GPU acceleration

set -e

source venv/bin/activate
echo "Running RIS+GA framework on GPU..."
python -m src.main --device gpu --config configs/gpu_config.yaml
