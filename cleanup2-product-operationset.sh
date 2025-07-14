#!/bin/bash
# cleanup-api-product-operationset.sh
# This script cleans up resources created by the script that applies
# an APIProduct and an APIOperationSet custom resource.

set -euo pipefail

echo "Starting cleanup script: Deleting APIProduct and APIOperationSet."

NAMESPACE="apim"
API_PRODUCT_NAME="api-product"
API_OPERATION_SET_NAME="item-set"

# Step 1: Delete the APIOperationSet custom resource
echo "🔄 Step 1: Deleting APIOperationSet '$API_OPERATION_SET_NAME' in namespace '$NAMESPACE'..."
kubectl delete apioperationset "$API_OPERATION_SET_NAME" \
  --namespace "$NAMESPACE" \
  --ignore-not-found=true || true

# Step 2: Delete the APIProduct custom resource
echo "🔄 Step 2: Deleting APIProduct '$API_PRODUCT_NAME' in namespace '$NAMESPACE'..."
kubectl delete apiproduct "$API_PRODUCT_NAME" \
  --namespace "$NAMESPACE" \
  --ignore-not-found=true || true

echo "✅ Cleanup complete: APIProduct and APIOperationSet removed."
