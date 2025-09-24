"""Proper unit tests for RR Set Generator"""

import sys
from pathlib import Path
import pytest

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import networkx as nx
from src.ris.rr_set_generator import RRSetGenerator
from src.utils.logger import setup_logger

class TestRRSetGenerator:
    """Test cases for RRSetGenerator class."""
    
    def setup_method(self):
        """Setup test graph."""
        self.G = nx.DiGraph()
        self.G.add_edges_from([
            (0, 1, {'influence_prob': 0.1}),
            (1, 2, {'influence_prob': 0.2}),
            (0, 2, {'influence_prob': 0.15}),
            (2, 3, {'influence_prob': 0.1})
        ])
        
    def test_initialization(self):
        """Test RRSetGenerator initialization."""
        generator = RRSetGenerator(
            graph=self.G,
            diffusion_model='IC',
            parallel_workers=2,
            random_seed=42
        )
        
        assert generator.num_nodes == 4
        assert generator.diffusion_model == 'IC'
        assert generator.parallel_workers == 2
        
    def test_rr_set_generation(self):
        """Test RR set generation."""
        generator = RRSetGenerator(
            graph=self.G,
            diffusion_model='IC',
            parallel_workers=2,
            random_seed=42
        )
        
        rr_sets = generator.generate_rr_sets(theta=10)
        
        assert len(rr_sets) == 10
        assert all(isinstance(rr_set.nodes, set) for rr_set in rr_sets)
        assert all(rr_set.root_node in rr_set.nodes for rr_set in rr_sets)
        
    def test_influence_estimation(self):
        """Test influence spread estimation."""
        generator = RRSetGenerator(
            graph=self.G,
            diffusion_model='IC',
            parallel_workers=2,
            random_seed=42
        )
        
        rr_sets = generator.generate_rr_sets(theta=100)
        seed_set = {0, 1}
        influence = generator.estimate_influence_spread(seed_set, rr_sets)
        
        assert isinstance(influence, float)
        assert influence >= 0
        assert influence <= 4  # Can't exceed number of nodes

# For backward compatibility with direct execution
def test_basic_functionality():
    """Basic functionality test for direct execution."""
    logger = setup_logger('test_rr_generator')
    
    # Create simple test graph
    G = nx.DiGraph()
    G.add_edges_from([
        (0, 1, {'influence_prob': 0.1}),
        (1, 2, {'influence_prob': 0.2}),
        (0, 2, {'influence_prob': 0.15}),
        (2, 3, {'influence_prob': 0.1})
    ])
    
    logger.info(f"Test graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
    
    # Initialize generator
    generator = RRSetGenerator(
        graph=G,
        diffusion_model='IC',
        parallel_workers=2,
        random_seed=42
    )
    
    # Generate RR sets
    theta = 10
    rr_sets = generator.generate_rr_sets(theta)
    
    # Test results
    logger.info(f"Generated {len(rr_sets)} RR sets")
    
    # Get statistics
    stats = generator.get_statistics(rr_sets)
    for key, value in stats.items():
        logger.info(f"{key}: {value}")
    
    # Test influence estimation
    seed_set = {0, 1}
    influence = generator.estimate_influence_spread(seed_set, rr_sets)
    logger.info(f"Estimated influence for seed set {seed_set}: {influence}")
    
    logger.info("Basic test completed successfully!")

if __name__ == "__main__":
    pytest.main([__file__])
