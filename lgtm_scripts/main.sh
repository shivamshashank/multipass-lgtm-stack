#!/bin/bash
# =================================================================
# 🚀 LGTM STACK MASTER CONTROLLER
# =================================================================
# This script orchestrates the deployment of the LGTM stack.
# It assumes all 01-08 scripts are in the CURRENT directory.
# =================================================================

# Error handling: Exit immediately if any command fails
set -e

# -----------------------------------------------------------------
# PHASE 1: Host Machine Setup
# -----------------------------------------------------------------
echo ""
echo "🖥️  [PHASE 1] HOST MACHINE SETUP"
echo "---------------------------------------------------"

if [ ! -f "./01_host_launch.sh" ]; then
    echo "❌ Error: Script '01_host_launch.sh' not found in current directory."
    exit 1
fi

echo "🍏 Running Script 01: Host Launch..."
chmod +x ./01_host_launch.sh
./01_host_launch.sh

# -----------------------------------------------------------------
# PHASE 2: VM Execution (Transfer & Run)
# -----------------------------------------------------------------
echo ""
echo "⚙️  [PHASE 2] EXECUTING VM CONFIGURATION"
echo "---------------------------------------------------"

# Helper function to Transfer -> Chmod -> Run
run_in_vm() {
    SCRIPT_NAME=$1
    USE_SUDO=$2
    
    # 1. Check if file exists locally
    if [ ! -f "./$SCRIPT_NAME" ]; then
        echo "❌ Error: File './$SCRIPT_NAME' not found!"
        exit 1
    fi

    # 2. Transfer
    echo "    -> Uploading $SCRIPT_NAME..."
    multipass transfer "$SCRIPT_NAME" demo:/home/ubuntu/

    # 3. Make executable (using absolute path for safety)
    multipass exec demo -- chmod +x /home/ubuntu/$SCRIPT_NAME

    # 4. Execute
    echo "▶️  Running $SCRIPT_NAME inside Multipass..."
    
    if [ "$USE_SUDO" == "true" ]; then
        # Run with sudo (System setup, Containerd, K8s install)
        # We use the full path /home/ubuntu/... to be safe
        multipass exec demo -- sudo /home/ubuntu/$SCRIPT_NAME
    else
        # Run as 'ubuntu' user (Helm, Kubeconfig, App deployment)
        multipass exec demo -- /home/ubuntu/$SCRIPT_NAME
    fi
}

# --- SYSTEM & K8S INSTALLATION (Requires Root/Sudo) ---
run_in_vm "02_vm_prep.sh" "true"
run_in_vm "03_containerd_setup.sh" "true"
run_in_vm "04_k8s_install.sh" "true"
run_in_vm "05_cluster_init.sh" "true"
run_in_vm "06_infra_setup.sh" "true"

# --- APPLICATION DEPLOYMENT (Run as Standard User) ---
run_in_vm "07_helm_configs.sh" "false"
run_in_vm "08_deploy_stack.sh" "false"

# -----------------------------------------------------------------
# COMPLETION
# -----------------------------------------------------------------
# Extract the IP address from Multipass info
VM_IP=$(multipass info demo | grep IPv4 | awk '{print $2}')

echo ""
echo "***************************************************"
echo "🎉 GLOBAL SUCCESS! THE STACK IS LIVE."
echo "***************************************************"
echo ""
echo "🌍 Access Grafana: http://grafana.${VM_IP}.nip.io"
echo "🔑 Login:          admin / admin"
echo ""
echo "To stop the VM later, run: multipass stop demo"
echo "***************************************************"