"""
Device detection and management for CPU/GPU execution.
"""

import logging
from typing import Tuple, Any, Dict

import torch

logger = logging.getLogger(__name__)


class DeviceManager:
    """Manages device selection and capabilities."""

    def __init__(self, preferred_device: str = "auto"):
        self.preferred_device = preferred_device
        self.device = self._select_device()
        self._log_device_info()

    def _select_device(self) -> torch.device:
        """Select optimal device based on availability and preference."""
        if self.preferred_device == "cpu":
            return torch.device("cpu")

        if self.preferred_device in ("gpu", "auto"):
            if torch.cuda.is_available():
                return torch.device("cuda")
            logger.warning("CUDA not available, falling back to CPU")
            return torch.device("cpu")

        return torch.device("cpu")

    def _log_device_info(self):
        """Log device information."""
        logger.info(f"Using device: {self.device}")

        if self.device.type == "cuda":
            gpu_name = torch.cuda.get_device_name(0)
            gpu_memory = torch.cuda.get_device_properties(0).total_memory / 1e9
            logger.info(f"GPU: {gpu_name}, Memory: {gpu_memory} GB")

    def get_device_info(self) -> Tuple[str, Dict[str, Any]]:
        """Return device type and detailed info dictionary."""
        info: Dict[str, Any] = {"device": str(self.device), "type": self.device.type}
        if self.device.type == "cuda":
            info["name"] = torch.cuda.get_device_name(0)
            info["memory_gb"] = torch.cuda.get_device_properties(0).total_memory / 1e9
            info["cuda_version"] = torch.version.cuda
        return self.device.type, info
