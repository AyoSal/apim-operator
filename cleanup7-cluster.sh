#!/bin/bash
# cleanup-gke-cluster.sh
# This script cleans up the GKE cluster created by the corresponding setup script.

set -euo pipefail

echo "Starting cleanup script: Deleting GKE Cluster."

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: No PROJECT_ID variable set. Please set it (e.g., export PROJECT_ID=\"your-gcp-project-id\") and re-run."
  exit 1
fi

# Source default values to get CLUSTER_NAME and ZONE
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Ensure that 1_defaults_apim_operator.sh exists in the same directory as this script,
# or adjust the path accordingly.
source "$SCRIPT_DIR/1_defaults_apim_operator.sh"

echo "Using Project ID: $PROJECT_ID"
echo "Target Cluster Name: $CLUSTER_NAME"
echo "Target Zone: $ZONE"
echo ""

# Step 1: Delete the GKE Cluster
echo "🔄 Step 1: Deleting GKE Cluster '$CLUSTER_NAME' in zone '$ZONE'..."
# The --quiet flag suppresses prompts.
# The --async flag can be used for non-blocking deletion, but waiting is safer for cleanup scripts.
gcloud container clusters delete "$CLUSTER_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --quiet \
  --async # Use async to allow the script to continue without waiting for full deletion completion.

echo "✅ GKE Cluster deletion command initiated for '$CLUSTER_NAME'. This may take some time to complete."
echo "You can check its status using: gcloud container clusters list --project=$PROJECT_ID --zone=$ZONE"
echo ""

echo "✅ Cleanup complete: GKE Cluster deletion process started."

