from setuptools import setup, find_packages

setup(
    name="ris_ga_im_project",
    version="0.1.0",
    author="MB Jallow",
    author_email="mbjallow6@gmail.com",
    description="Hybrid Reverse Influence Sampling + Genetic Algorithm Framework for Public Health",
    long_description=open("README.md", encoding="utf-8").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/mbjallow6/ris-ga-influence-maximization",
    license="MIT",
    packages=find_packages(where="src") or find_packages(),
    package_dir={"": "src"},
    install_requires=[
        # Core dependencies
        "numpy>=1.24.0",
        "scipy>=1.10.0",
        "networkx>=3.0",
        "pandas>=2.0.0",
        "pyyaml>=6.0",
        "torch>=2.0.0",
        "deap>=1.4.1",
    ],
    extras_require={
        "dev": [
            "black>=23.9.1",
            "flake8>=6.0.0",
            "mypy>=1.5.1",
            "pre-commit>=2.20.0",
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
        ],
        "notebook": ["jupyter>=1.0.0", "ipykernel>=6.25.0"],
    },
    entry_points={
        "console_scripts": [
            "ris-ga=src.main:main",
        ],
    },
    python_requires=">=3.9",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)
