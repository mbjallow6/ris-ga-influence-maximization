"""
Reverse Influence Sampling (RIS) module for the RIS+GA framework.

This module implements efficient RIS algorithms optimized for multi-core systems,
providing the foundation for influence maximization through
reverse reachable set sampling.
"""

from .rr_set_generator import RRSetGenerator, RRSet

__all__ = [
    "RRSetGenerator",
    "RRSet",
]
