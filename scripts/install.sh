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
