# Makefile for RIS+GA Influence Maximization Framework

# Variables
VENV      := venv
PYTHON    := $(VENV)/bin/python
PIP       := $(VENV)/bin/pip
BLACK     := $(VENV)/bin/black
FLAKE8    := $(VENV)/bin/flake8
MYPY      := $(VENV)/bin/mypy
PYTEST    := $(VENV)/bin/pytest

.PHONY: help install lint typecheck test clean run run-gpu

help:
	@echo "Usage:"
	@echo "  make install     # Create venv & install dependencies"
	@echo "  make lint        # Run black and flake8"
	@echo "  make typecheck   # Run mypy"
	@echo "  make test        # Run pytest"
	@echo "  make run         # Run with CPU"
	@echo "  make run-gpu     # Run with GPU"
	@echo "  make clean       # Clean caches and venv"

install:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	$(PIP) install -e .

lint:
	$(BLACK) src/ tests/
	$(FLAKE8) src/ tests/

typecheck:
	$(MYPY) --ignore-missing-imports src/


test:
	$(PYTEST) tests/ --maxfail=1 --disable-warnings -q

run:
	$(PYTHON) -m src.main --device cpu --config configs/cpu_config.yaml

run-gpu:
	$(PYTHON) -m src.main --device gpu --config configs/gpu_config.yaml

clean:
# 	rm -rf $(VENV)
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -name "*.pyc" -delete
	rm -rf .pytest_cache .mypy_cache .cache
