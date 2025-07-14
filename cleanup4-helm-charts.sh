#!/bin/bash
# cleanup-apim-operator-helm.sh
# This script cleans up the Helm releases created by the original script that
# installs Apigee APIM CRDs and the Apigee APIM Operator.

set -euo pipefail

echo "Starting cleanup script: Uninstalling Apigee APIM Operator Helm releases."

# Source default values to get variables like KSA_NAMESPACE
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Ensure that 1_defaults_apim_operator.sh exists in the same directory as this script,
# or adjust the path accordingly.
source "$SCRIPT_DIR/1_defaults_apim_operator.sh"

# Define the Helm release names
APIM_OPERATOR_RELEASE_NAME="apigee-apim-operator"
APIM_CRDS_RELEASE_NAME="apigee-apim-crds"

echo "Using Namespace: ${KSA_NAMESPACE}"
echo ""

# Step 1: Uninstall the Apigee APIM Operator Helm release
echo "🔄 Step 1: Uninstalling Helm release '$APIM_OPERATOR_RELEASE_NAME' in namespace '${KSA_NAMESPACE}'..."
helm uninstall "$APIM_OPERATOR_RELEASE_NAME" \
  --namespace "${KSA_NAMESPACE}" \
  --wait # Wait for the uninstallation to complete

# Check the exit status of the previous command
if [ $? -eq 0 ]; then
  echo "✅ Helm release '$APIM_OPERATOR_RELEASE_NAME' uninstallation initiated successfully."
else
  echo "❌ Error: Helm release '$APIM_OPERATOR_RELEASE_NAME' uninstallation failed or release not found."
fi

# Step 2: Uninstall the Apigee APIM CRDs Helm release
# It's important to uninstall the operator first, then the CRDs,
# as CRDs might be dependencies for the operator.
echo "🔄 Step 2: Uninstalling Helm release '$APIM_CRDS_RELEASE_NAME' in namespace '${KSA_NAMESPACE}'..."
helm uninstall "$APIM_CRDS_RELEASE_NAME" \
  --namespace "${KSA_NAMESPACE}" \
  --wait # Wait for the uninstallation to complete

# Check the exit status of the previous command
if [ $? -eq 0 ]; then
  echo "✅ Helm release '$APIM_CRDS_RELEASE_NAME' uninstallation initiated successfully."
else
  echo "❌ Error: Helm release '$APIM_CRDS_RELEASE_NAME' uninstallation failed or release not found."
fi

echo ""
echo "✅ Cleanup complete: Apigee APIM Operator and CRDs Helm releases removed."
