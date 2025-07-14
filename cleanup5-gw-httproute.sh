#!/bin/bash
# cleanup-k8s-gateway-httpbin.sh
# This script cleans up Kubernetes Gateway API objects (Gateway, HTTPRoute)
# and the httpbin application (Namespace, ServiceAccount, Service, Deployment)
# created by the corresponding deployment script.

set -euo pipefail

echo "Starting cleanup script: Deleting Kubernetes Gateway API objects and httpbin app."

# Define resource names and namespaces
GATEWAY_NAME="global-ext-bin"
GATEWAY_NAMESPACE="default"

HTTPROUTE_NAME="http-bin-route"
HTTPROUTE_NAMESPACE="http"

HTTPBIN_NAMESPACE="http"
HTTPBIN_SERVICE_ACCOUNT="httpbin"
HTTPBIN_SERVICE="httpbin"
HTTPBIN_DEPLOYMENT="httpbin"


# Step 1: Delete the HTTPRoute custom resource
# HTTPRoute depends on the Gateway, so it's good to delete it before the Gateway.
echo "🔄 Step 1: Deleting HTTPRoute '$HTTPROUTE_NAME' in namespace '$HTTPROUTE_NAMESPACE'..."
kubectl delete httproute "$HTTPROUTE_NAME" \
  --namespace "$HTTPROUTE_NAMESPACE" \
  --ignore-not-found=true --wait=false || true
# Using --wait=false to not block if there are reconciliation delays.

# Step 2: Delete the Gateway custom resource
echo "🔄 Step 2: Deleting Gateway '$GATEWAY_NAME' in namespace '$GATEWAY_NAMESPACE'..."
kubectl delete gateway "$GATEWAY_NAME" \
  --namespace "$GATEWAY_NAMESPACE" \
  --ignore-not-found=true --wait=false || true

# Step 3: Delete the httpbin application resources by deleting the namespace.
# Deleting the namespace will automatically delete all resources within it
# (ServiceAccount, Service, Deployment).
echo "🔄 Step 3: Deleting httpbin Namespace '$HTTPBIN_NAMESPACE' (and its contents)..."
kubectl delete namespace "$HTTPBIN_NAMESPACE" \
  --ignore-not-found=true --wait=false || true

echo "✅ Cleanup commands initiated. It may take some time for resources to be fully terminated."

