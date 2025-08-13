#!/bin/bash

# Manual test script for issue #15190: uv sync --no-sources editable switch bug
# This script reproduces the issue described in the GitHub issue

set -e

echo "=== Manual Test for Issue #15190: uv sync --no-sources editable switch bug ==="
echo

# Build uv first
echo "Building uv..."
cargo build
echo

# Store the original directory
ORIG_DIR=$(pwd)
UV_PATH="$ORIG_DIR/target/debug/uv"

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"
cd "$TEST_DIR"

# Create main project
echo "1. Creating main project..."
$UV_PATH init hello-world --package
cd hello-world

# Create local dependency that mimics anyio
echo "2. Creating local dependency that mimics anyio..."
mkdir -p local_dep

# Set up local_dep/pyproject.toml as a local anyio package
cat > local_dep/pyproject.toml << 'EOF'
[project]
name = "anyio"
version = "4.3.0"
description = "Local test package mimicking anyio"
requires-python = ">=3.8"

[build-system]
requires = ["setuptools>=61", "wheel"]
build-backend = "setuptools.build_meta"
EOF

# Create a minimal Python package structure
mkdir -p local_dep/anyio
cat > local_dep/anyio/__init__.py << 'EOF'
"""Local test package mimicking anyio"""
__version__ = "4.3.0"
EOF

# Set up main project to depend on anyio with editable source
cat > pyproject.toml << 'EOF'
[project]
name = "test-no-sources"
version = "0.0.1"
requires-python = ">=3.8"
dependencies = ["anyio"]

[tool.uv.sources]
anyio = { path = "./local_dep", editable = true }

[build-system]
requires = ["setuptools>=67"]
build-backend = "setuptools.build_meta"
EOF

echo "3. Testing the three-step scenario..."
echo

# Step 1: uv sync --no-sources (should install anyio from PyPI)
echo "Step 1: Running 'uv sync --no-sources' (should install anyio from PyPI)"
$UV_PATH sync --no-sources
echo "Checking installed packages:"
$UV_PATH pip list
echo

# Step 2: uv sync (should switch anyio to editable from local_dep)
echo "Step 2: Running 'uv sync' (should switch anyio to editable from local_dep)"
$UV_PATH sync
echo "Checking installed packages:"
$UV_PATH pip list
echo

# Step 3: uv sync --no-sources (should switch anyio back to PyPI)
echo "Step 3: Running 'uv sync --no-sources' again (should switch anyio back to PyPI)"
$UV_PATH sync --no-sources
echo "Checking installed packages:"
$UV_PATH pip list
echo

# Check the final result
echo "=== Final verification ==="
echo "Looking for anyio installation details..."
if $UV_PATH pip show anyio | grep -q "file://"; then
    echo "❌ FAILED: anyio is still installed as editable (from file://)"
    echo "This indicates the bug is still present"
else
    echo "✅ SUCCESS: anyio is installed from PyPI (not editable)"
    echo "This indicates the bug has been fixed"
fi

echo
echo "Test completed. Directory: $TEST_DIR"
echo "You can inspect the environment manually if needed."