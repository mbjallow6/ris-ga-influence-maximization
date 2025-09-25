"""
Configuration management for the RIS+GA framework.

This module handles all configuration parameters, including:
- Algorithm hyperparameters
- Hardware settings (CPU/GPU)
- File paths and data sources
- Logging configuration
"""

# import os
import yaml  # type: ignore
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass


@dataclass
class RISConfig:
    """RIS algorithm configuration."""

    theta: int = 1000
    epsilon: float = 0.1
    max_iterations: int = 100
    parallel_workers: int = 4


@dataclass
class GAConfig:
    """Genetic Algorithm configuration."""

    population_size: int = 100
    generations: int = 50
    crossover_rate: float = 0.8
    mutation_rate: float = 0.1
    tournament_size: int = 3
    elite_size: int = 5


@dataclass
class ObjectiveConfig:
    """Multi-objective optimization weights."""

    influence_weight: float = 0.4
    cost_weight: float = 0.3
    equity_weight: float = 0.3
    time_weight: float = 0.0


class Config:
    """Enhanced configuration management."""

    def __init__(self, config_path: Optional[str] = None):
        self.project_root = Path(__file__).parent.parent
        self.config_data = self._load_config(config_path)

        # Initialize structured configs
        self.ris = RISConfig(**self.config_data.get("ris", {}))
        self.ga = GAConfig(**self.config_data.get("ga", {}))
        self.objectives = ObjectiveConfig(**self.config_data.get("objectives", {}))

    def _load_config(self, config_path: Optional[str]) -> Dict[str, Any]:
        """Load configuration from file or defaults."""
        default_config = {
            "device": "cpu",
            "random_seed": 42,
            "data_dir": "data",
            "log_level": "INFO",
            "ris": {},
            "ga": {},
            "objectives": {},
        }

        if config_path and Path(config_path).exists():
            with open(config_path, "r") as f:
                user_config = yaml.safe_load(f)
                default_config.update(user_config)

        return default_config

    @property
    def data_dir(self) -> Path:
        """Get data directory path."""
        return self.project_root / self.config_data["data_dir"]

    def get(self, key: str, default=None):
        """Get configuration value by dot notation."""
        keys = key.split(".")
        value = self.config_data

        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        return value
