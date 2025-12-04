#!/bin/bash
# 01_host_launch.sh
# ---------------------------------------------
# 🚀 Launches the Multipass VM with specs required for LGTM Stack
# ---------------------------------------------
set -e

echo "🍏 [Host] Checking/Installing Multipass..."
if ! command -v multipass &> /dev/null; then
    brew install multipass
else
    echo "    Multipass is already installed."
fi

echo "🗑️  [Host] Deleting any existing 'demo' VM..."
# We delete and purge to free up the name 'demo'
multipass delete demo --purge 2>/dev/null || true

echo "🚀 [Host] Launching VM 'demo' (8 CPUs, 8GB RAM, 32GB Disk)..."
# Note: 4 CPUs is minimum recommended, 8GB RAM is required for full stack
multipass launch --name demo --memory 8G --disk 32G --cpus 4

echo "✅ [Host] VM Ready! Enter the shell with:"
echo "    multipass shell demo"