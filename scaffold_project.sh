#!/usr/bin/env bash

# scaffold_project.sh
# Creates the RIS+GA Influence Maximization project directory structure

set -e

BASE_DIR="ris_ga_im_project"

echo "Creating RIS+GA Influence Maximization project structure..."

if [ -d "$BASE_DIR" ]; then
  echo "Error: '$BASE_DIR' already exists. Please remove or rename it first."
  exit 1
fi

# Create directory structure
mkdir -p $BASE_DIR/{ci,data/{raw,processed,public_health},docs,notebooks,scripts,src/{ris,ga,evaluation,utils},tests}

echo "✓ Directory structure created"

# Root configuration files
touch $BASE_DIR/{.gitignore,Dockerfile,docker-compose.yml,LICENSE,README.md,requirements.txt,setup.py}

# CI/CD files
touch $BASE_DIR/ci/{github-actions.yml,Jenkinsfile}

# Documentation
cat << 'EOF' > $BASE_DIR/docs/architecture.md
# RIS+GA Influence Maximization Architecture

## Overview
This document describes the architectural decisions and design patterns used in the RIS+GA framework.

## Core Components
- **RIS Module**: Reverse Influence Sampling implementation
- **GA Module**: Genetic Algorithm optimization framework
- **Evaluation**: Multi-objective fitness evaluation and metrics
- **Utils**: Shared utilities for logging, configuration, and reproducibility

## Data Flow
[To be documented during development]

## Design Decisions
[To be updated as architectural decisions are made]
EOF

# Notebook templates
cat << 'EOF' > $BASE_DIR/notebooks/01_data_exploration.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Exploration and Network Analysis\n",
    "\n",
    "This notebook explores the structure and properties of public health networks."
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

cat << 'EOF' > $BASE_DIR/notebooks/02_ris_sampler_demo.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# RIS Sampler Demonstration\n",
    "\n",
    "This notebook demonstrates the Reverse Influence Sampling implementation."
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

cat << 'EOF' > $BASE_DIR/notebooks/03_ga_optimizer_demo.ipynb
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Genetic Algorithm Optimizer Demonstration\n",
    "\n",
    "This notebook demonstrates the genetic algorithm implementation and multi-objective optimization."
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Scripts
cat << 'EOF' > $BASE_DIR/scripts/install.sh
#!/usr/bin/env bash

# install.sh
# Sets up the development environment for the RIS+GA project

set -e

echo "Setting up RIS+GA development environment..."

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt

echo "✓ Development environment setup complete"
echo "✓ Activate with: source venv/bin/activate"
EOF

cat << 'EOF' > $BASE_DIR/scripts/run_cpu.sh
#!/usr/bin/env bash

# run_cpu.sh
# Runs the RIS+GA framework using CPU only

set -e

source venv/bin/activate
export CUDA_VISIBLE_DEVICES=""
echo "Running RIS+GA framework on CPU..."
python -m src.main --device cpu --config configs/cpu_config.yaml
EOF

cat << 'EOF' > $BASE_DIR/scripts/run_gpu.sh
#!/usr/bin/env bash

# run_gpu.sh
# Runs the RIS+GA framework using GPU acceleration

set -e

source venv/bin/activate
echo "Running RIS+GA framework on GPU..."
python -m src.main --device gpu --config configs/gpu_config.yaml
EOF

# Make scripts executable
chmod +x $BASE_DIR/scripts/*.sh

# Source code files
cat << 'EOF' > $BASE_DIR/src/__init__.py
"""
RIS+GA Influence Maximization Framework

A scalable framework combining Reverse Influence Sampling with Genetic Algorithms
for multi-objective influence maximization in public health interventions.
"""

__version__ = "0.1.0"
__author__ = "RIS+GA Development Team"
EOF

cat << 'EOF' > $BASE_DIR/src/config.py
"""
Configuration management for the RIS+GA framework.

This module handles all configuration parameters, including:
- Algorithm hyperparameters
- Hardware settings (CPU/GPU)
- File paths and data sources
- Logging configuration
"""

import os
from typing import Dict, Any
import yaml


class Config:
    """Central configuration management class."""
    
    def __init__(self, config_path: str = None):
        """Initialize configuration from file or defaults."""
        self.config = self._load_default_config()
        
        if config_path and os.path.exists(config_path):
            with open(config_path, 'r') as f:
                user_config = yaml.safe_load(f)
                self.config.update(user_config)
    
    def _load_default_config(self) -> Dict[str, Any]:
        """Load default configuration parameters."""
        return {
            'device': 'cpu',
            'random_seed': 42,
            'ris': {
                'theta': 1000,
                'epsilon': 0.1
            },
            'ga': {
                'population_size': 100,
                'generations': 50,
                'crossover_rate': 0.8,
                'mutation_rate': 0.1
            },
            'objectives': {
                'influence_weight': 0.4,
                'cost_weight': 0.3,
                'equity_weight': 0.3
            }
        }
    
    def get(self, key: str, default=None):
        """Get configuration value by key."""
        keys = key.split('.')
        value = self.config
        
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        
        return value
EOF

cat << 'EOF' > $BASE_DIR/src/main.py
"""
Main entry point for the RIS+GA Influence Maximization framework.
"""

import argparse
import sys
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.config import Config
from src.utils.logger import setup_logger
from src.utils.seed_control import set_random_seed


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='RIS+GA Influence Maximization Framework'
    )
    parser.add_argument(
        '--config', 
        type=str, 
        help='Path to configuration file'
    )
    parser.add_argument(
        '--device', 
        choices=['cpu', 'gpu'], 
        default='cpu',
        help='Computing device to use'
    )
    
    args = parser.parse_args()
    
    # Initialize configuration
    config = Config(args.config)
    
    # Setup logging
    logger = setup_logger('ris_ga_main')
    
    # Set random seed for reproducibility
    set_random_seed(config.get('random_seed', 42))
    
    logger.info("RIS+GA Influence Maximization Framework starting...")
    logger.info(f"Using device: {args.device}")
    
    # TODO: Initialize and run the main algorithm
    logger.info("Framework initialization complete")


if __name__ == "__main__":
    main()
EOF

# Utility files
touch $BASE_DIR/src/ris/{__init__.py,rr_set_generator.py,sampler.py}
touch $BASE_DIR/src/ga/{__init__.py,population.py,operators.py,optimizer.py}
touch $BASE_DIR/src/evaluation/{__init__.py,metrics.py,validator.py}

cat << 'EOF' > $BASE_DIR/src/utils/__init__.py
"""Utility modules for the RIS+GA framework."""
EOF

cat << 'EOF' > $BASE_DIR/src/utils/logger.py
"""
Logging configuration and utilities.
"""

import logging
import sys
from typing import Optional


def setup_logger(
    name: str, 
    level: int = logging.INFO,
    format_string: Optional[str] = None
) -> logging.Logger:
    """Setup a logger with consistent formatting."""
    
    if format_string is None:
        format_string = (
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Create handler if none exists
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(level)
        
        # Create formatter
        formatter = logging.Formatter(format_string)
        handler.setFormatter(formatter)
        
        logger.addHandler(handler)
    
    return logger
EOF

cat << 'EOF' > $BASE_DIR/src/utils/seed_control.py
"""
Random seed control for reproducible experiments.
"""

import random
import numpy as np


def set_random_seed(seed: int) -> None:
    """Set random seed for reproducibility across libraries."""
    random.seed(seed)
    np.random.seed(seed)
    
    # Set PyTorch seed if available
    try:
        import torch
        torch.manual_seed(seed)
        if torch.cuda.is_available():
            torch.cuda.manual_seed(seed)
            torch.cuda.manual_seed_all(seed)
    except ImportError:
        pass
EOF

# Test files
touch $BASE_DIR/tests/{__init__.py,test_rr_set_generator.py,test_sampler.py,test_population.py,test_operators.py,test_optimizer.py,test_end_to_end.py}

# Data directory README files
cat << 'EOF' > $BASE_DIR/data/README.md
# Data Directory

## Structure
- `raw/`: Original, unmodified datasets
- `processed/`: Cleaned and preprocessed graph data  
- `public_health/`: Domain-specific public health network datasets

## Data Sources
[Document data sources and acquisition methods here]

## Preprocessing Pipeline
[Document data preprocessing steps here]
EOF

echo "✓ Project scaffolding complete!"
echo ""
echo "Next steps:"
echo "1. cd $BASE_DIR"
echo "2. ./scripts/install.sh"
echo "3. Edit requirements.txt with needed dependencies"
echo "4. Update README.md with project description"
echo "5. Start implementing core modules"
