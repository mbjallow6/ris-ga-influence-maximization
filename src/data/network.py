"""
Health-specific network data structure.
"""

import networkx as nx
import numpy as np
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass


@dataclass
class NodeAttributes:
    """Health network node attributes."""
    node_id: int
    cost: float = 1.0
    demographic_group: str = "general"
    health_literacy: float = 0.5
    trust_level: float = 0.5
    reach_potential: float = 1.0


@dataclass
class EdgeAttributes:
    """Health network edge attributes."""
    source: int
    target: int
    influence_prob: float = 0.1
    trust_strength: float = 0.5
    interaction_frequency: float = 1.0


class HealthNetwork:
    """Health-specific network wrapper around NetworkX."""
    
    def __init__(self, graph: nx.DiGraph = None):
        self.graph = graph or nx.DiGraph()
        self._node_attrs = {}
        self._edge_attrs = {}
    
    def add_node(self, node_id: int, **attributes):
        """Add node with health-specific attributes."""
        self.graph.add_node(node_id, **attributes)
        self._node_attrs[node_id] = NodeAttributes(
            node_id=node_id,
            **attributes
        )
    
    def add_edge(self, source: int, target: int, **attributes):
        """Add edge with health-specific attributes."""
        self.graph.add_edge(source, target, **attributes)
        self._edge_attrs[(source, target)] = EdgeAttributes(
            source=source,
            target=target,
            **attributes
        )
    
    def get_node_cost(self, node_id: int) -> float:
        """Get intervention cost for node."""
        return self._node_attrs.get(node_id, NodeAttributes(node_id)).cost
    
    def get_edge_probability(self, source: int, target: int) -> float:
        """Get influence probability for edge."""
        return self._edge_attrs.get(
            (source, target), 
            EdgeAttributes(source, target)
        ).influence_prob
    
    def get_demographic_groups(self) -> Dict[str, List[int]]:
        """Get nodes grouped by demographic."""
        groups = {}
        for node_id, attrs in self._node_attrs.items():
            group = attrs.demographic_group
            if group not in groups:
                groups[group] = []
            groups[group].append(node_id)
        return groups
    
    @property
    def num_nodes(self) -> int:
        """Number of nodes in network."""
        return self.graph.number_of_nodes()
    
    @property  
    def num_edges(self) -> int:
        """Number of edges in network."""
        return self.graph.number_of_edges()
