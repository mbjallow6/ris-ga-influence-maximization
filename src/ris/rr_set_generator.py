"""
Reverse Reachable (RR) Set Generator for RIS algorithm.

This module implements parallel generation of RR sets with memory optimization
and support for different diffusion models (Independent Cascade, Linear Threshold).
"""

import random
import numpy as np
import networkx as nx
from typing import List, Set, Dict, Tuple, Optional
from multiprocessing import Pool, Manager
from concurrent.futures import ProcessPoolExecutor, as_completed
import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class RRSet:
    """Represents a single Reverse Reachable set."""
    nodes: Set[int]
    root_node: int
    size: int
    
    def __post_init__(self):
        self.size = len(self.nodes)


class RRSetGenerator:
    """
    Generates Reverse Reachable (RR) sets for influence maximization.
    
    Optimized for multi-core systems with parallel processing and memory management.
    """
    
    def __init__(self, 
                 graph: nx.DiGraph,
                 diffusion_model: str = 'IC',  # Independent Cascade
                 parallel_workers: int = 4,
                 random_seed: int = 42):
        """
        Initialize RR Set Generator.
        
        Args:
            graph: Directed graph representing the network
            diffusion_model: 'IC' (Independent Cascade) or 'LT' (Linear Threshold)
            parallel_workers: Number of parallel processes
            random_seed: Random seed for reproducibility
        """
        self.graph = graph
        self.nodes = list(graph.nodes())
        self.num_nodes = len(self.nodes)
        self.diffusion_model = diffusion_model.upper()
        self.parallel_workers = parallel_workers
        self.random_seed = random_seed
        
        # Validate diffusion model
        if self.diffusion_model not in ['IC', 'LT']:
            raise ValueError("diffusion_model must be 'IC' or 'LT'")
        
        # Pre-compute edge probabilities for efficiency
        self._edge_probs = self._precompute_edge_probabilities()
        
        logger.info(f"RRSetGenerator initialized: {self.num_nodes} nodes, "
                   f"{self.graph.number_of_edges()} edges, "
                   f"model: {self.diffusion_model}, workers: {self.parallel_workers}")

    def _precompute_edge_probabilities(self) -> Dict[Tuple[int, int], float]:
        """Precompute edge probabilities for faster access."""
        edge_probs = {}
        
        for u, v, data in self.graph.edges(data=True):
            # Use 'influence_prob' if available, otherwise default
            prob = data.get('influence_prob', data.get('weight', 0.1))
            edge_probs[(u, v)] = min(max(prob, 0.0), 1.0)  # Clamp to [0,1]
            
        return edge_probs

    def _generate_single_rr_set_ic(self, root_node: int, worker_seed: int) -> RRSet:
        """
        Generate single RR set using Independent Cascade model.
        
        Args:
            root_node: Starting node for reverse reachable set
            worker_seed: Random seed for this worker
            
        Returns:
            RRSet object containing reachable nodes
        """
        # Fix: Convert numpy types to Python int
        worker_seed = int(worker_seed)
        root_node = int(root_node)
        
        np.random.seed(worker_seed)
        random.seed(worker_seed)
        
        # Reverse BFS from root_node
        rr_set = {root_node}
        queue = [root_node]
        
        while queue:
            current = queue.pop(0)
            
            # Check all incoming edges to current node
            for predecessor in self.graph.predecessors(current):
                edge_prob = self._edge_probs.get((predecessor, current), 0.1)
                
                # Flip coin for influence propagation (reverse direction)
                if predecessor not in rr_set and np.random.random() < edge_prob:
                    rr_set.add(predecessor)
                    queue.append(predecessor)
        
        return RRSet(nodes=rr_set, root_node=root_node, size=len(rr_set))

    def _generate_single_rr_set_lt(self, root_node: int, worker_seed: int) -> RRSet:
        """
        Generate single RR set using Linear Threshold model.
        
        Args:
            root_node: Starting node for reverse reachable set
            worker_seed: Random seed for this worker
            
        Returns:
            RRSet object containing reachable nodes
        """
        # Fix: Convert numpy types to Python int
        worker_seed = int(worker_seed)
        root_node = int(root_node)
        
        np.random.seed(worker_seed)
        random.seed(worker_seed)
        
        # For LT model, we need to consider node thresholds
        rr_set = {root_node}
        
        # Simplified LT implementation - can be enhanced based on specific requirements
        # For now, using probabilistic approach similar to IC
        queue = [root_node]
        
        while queue:
            current = queue.pop(0)
            
            for predecessor in self.graph.predecessors(current):
                edge_prob = self._edge_probs.get((predecessor, current), 0.1)
                
                # In LT, threshold is typically sum of incoming edge weights
                if predecessor not in rr_set and np.random.random() < edge_prob:
                    rr_set.add(predecessor)
                    queue.append(predecessor)
        
        return RRSet(nodes=rr_set, root_node=root_node, size=len(rr_set))

    def generate_rr_sets(self, theta: int) -> List[RRSet]:
        """
        Generate theta RR sets using parallel processing.
        
        Args:
            theta: Number of RR sets to generate
            
        Returns:
            List of RRSet objects
        """
        logger.info(f"Generating {theta} RR sets using {self.parallel_workers} workers...")
        
        # Prepare random seeds for each RR set generation
        np.random.seed(self.random_seed)
        worker_seeds = np.random.randint(0, 2**31, size=theta)
        
        # Randomly select root nodes
        root_nodes = np.random.choice(self.nodes, size=theta, replace=True)
        
        # Convert numpy arrays to Python lists to avoid type issues
        tasks = list(zip([int(r) for r in root_nodes], [int(s) for s in worker_seeds]))
        
        rr_sets = []
        
        if self.parallel_workers == 1:
            # Single-threaded execution
            for root_node, seed in tasks:
                if self.diffusion_model == 'IC':
                    rr_set = self._generate_single_rr_set_ic(root_node, seed)
                else:
                    rr_set = self._generate_single_rr_set_lt(root_node, seed)
                rr_sets.append(rr_set)
        else:
            # Multi-threaded execution
            with ProcessPoolExecutor(max_workers=self.parallel_workers) as executor:
                if self.diffusion_model == 'IC':
                    futures = {
                        executor.submit(self._generate_single_rr_set_ic, root, seed): (root, seed)
                        for root, seed in tasks
                    }
                else:
                    futures = {
                        executor.submit(self._generate_single_rr_set_lt, root, seed): (root, seed)
                        for root, seed in tasks
                    }
                
                for future in as_completed(futures):
                    try:
                        rr_set = future.result()
                        rr_sets.append(rr_set)
                    except Exception as e:
                        root, seed = futures[future]
                        logger.error(f"RR set generation failed for root {root}: {e}")
        
        logger.info(f"Generated {len(rr_sets)} RR sets successfully")
        return rr_sets

    def estimate_influence_spread(self, seed_set: Set[int], rr_sets: List[RRSet]) -> float:
        """
        Estimate influence spread of seed set using RR sets.
        
        Args:
            seed_set: Set of seed nodes
            rr_sets: List of RR sets
            
        Returns:
            Estimated influence spread
        """
        if not rr_sets:
            return 0.0
        
        covered_sets = 0
        for rr_set in rr_sets:
            if rr_set.nodes & seed_set:  # Intersection not empty
                covered_sets += 1
        
        # Estimate influence as (covered_rr_sets / total_rr_sets) * num_nodes
        return (covered_sets / len(rr_sets)) * self.num_nodes

    def get_node_coverage(self, rr_sets: List[RRSet]) -> Dict[int, int]:
        """
        Get how many RR sets each node covers.
        
        Args:
            rr_sets: List of RR sets
            
        Returns:
            Dictionary mapping node_id to coverage count
        """
        coverage = {node: 0 for node in self.nodes}
        
        for rr_set in rr_sets:
            for node in rr_set.nodes:
                coverage[node] += 1
        
        return coverage

    def get_statistics(self, rr_sets: List[RRSet]) -> Dict[str, float]:
        """
        Get statistics about generated RR sets.
        
        Args:
            rr_sets: List of RR sets
            
        Returns:
            Dictionary with statistics
        """
        if not rr_sets:
            return {}
        
        sizes = [rr_set.size for rr_set in rr_sets]
        
        return {
            'total_rr_sets': len(rr_sets),
            'avg_rr_set_size': np.mean(sizes),
            'std_rr_set_size': np.std(sizes),
            'min_rr_set_size': np.min(sizes),
            'max_rr_set_size': np.max(sizes),
            'total_nodes_covered': len(set().union(*[rr_set.nodes for rr_set in rr_sets]))
        }