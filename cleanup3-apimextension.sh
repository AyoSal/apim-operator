#!/bin/bash
# cleanup-apim-extension-policy.sh
# This script cleans up resources created by the script that applies
# an APIMExtensionPolicy custom resource.

set -euo pipefail

echo "Starting cleanup script: Deleting APIMExtensionPolicy."

NAMESPACE="apim"
POLICY_NAME="global-ext-lb1-apim-policy"

# Step 1: Delete the APIMExtensionPolicy custom resource
echo "🔄 Step 1: Deleting APIMExtensionPolicy '$POLICY_NAME' in namespace '$NAMESPACE'..."
kubectl delete apimextensionpolicy "$POLICY_NAME" \
  --namespace "$NAMESPACE" \
  --ignore-not-found=true || true

echo "✅ Cleanup complete: APIMExtensionPolicy removed."
