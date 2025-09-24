#!/usr/bin/env bash

# run_cpu.sh
# Runs the RIS+GA framework using CPU only

set -e

source venv/bin/activate
export CUDA_VISIBLE_DEVICES=""
echo "Running RIS+GA framework on CPU..."
python -m src.main --device cpu --config configs/cpu_config.yaml
