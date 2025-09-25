import argparse
import sys
from pathlib import Path
from src.config import Config
from src.utils.logger import setup_logger
from src.utils.seed_control import set_random_seed

"""
Main entry point for the RIS+GA Influence Maximization framework.
"""
# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="RIS+GA Influence Maximization Framework"
    )
    parser.add_argument("--config", type=str, help="Path to configuration file")
    parser.add_argument(
        "--device",
        choices=["cpu", "gpu"],
        default="cpu",
        help="Computing device to use",
    )

    args = parser.parse_args()

    # Initialize configuration
    config = Config(args.config)

    # Setup logging
    logger = setup_logger("ris_ga_main")

    # Set random seed for reproducibility
    set_random_seed(config.get("random_seed", 42))

    logger.info("RIS+GA Influence Maximization Framework starting...")
    logger.info(f"Using device: {args.device}")

    # TODO: Initialize and run the main algorithm
    logger.info("Framework initialization complete")


if __name__ == "__main__":
    main()
