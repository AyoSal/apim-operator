#!/bin/bash
# cleanup-apim-operator-setup.sh
# This script cleans up resources created by the Apigee API Management Operator setup script,
# including GCP Service Accounts, IAM policy bindings, and Kubernetes namespaces.

set -euo pipefail

echo "Starting cleanup script: Removing Apigee API Management Operator setup resources."

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: No PROJECT_ID variable set. Please set it (e.g., export PROJECT_ID=\"your-gcp-project-id\") and re-run."
  exit 1
fi

# Source default values to get KSA_NAMESPACE, KSA_NAME, APIGEE_APIM_GSA_NAME
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Ensure that 1_defaults_apim_operator.sh exists in the same directory or adjust path
source "$SCRIPT_DIR/1_defaults_apim_operator.sh"

# Reconstruct full GSA email and Workload Identity KSA member format
APIGEE_APIM_GSA_EMAIL="${APIGEE_APIM_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
WI_KSA_MEMBER="serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]"

echo "Using Project ID: $PROJECT_ID"
echo "Target GSA: $APIGEE_APIM_GSA_EMAIL"
echo "Target KSA Namespace: $KSA_NAMESPACE"
echo "Target KSA Workload Identity Member: $WI_KSA_MEMBER"
echo ""

# --- Cleanup Steps ---

# Step 1: Delete the Kubernetes namespace
# This will also delete any Kubernetes Service Accounts (KSA) within it.
echo "🔄 Step 1: Deleting Kubernetes namespace '$KSA_NAMESPACE'..."
if kubectl get ns "${KSA_NAMESPACE}" &>/dev/null; then
  kubectl delete ns "${KSA_NAMESPACE}" --wait=true --ignore-not-found=true
  echo "✅ Namespace '${KSA_NAMESPACE}' deleted."
else
  echo "❕ Namespace '${KSA_NAMESPACE}' does not exist. Skipping deletion."
fi
echo ""

# Step 2: Remove IAM Policy Binding from GSA for Workload Identity
# This removes the permission for the KSA to impersonate the GSA.
echo "🔄 Step 2: Removing Workload Identity binding from GSA '$APIGEE_APIM_GSA_EMAIL'..."
if gcloud iam service-accounts get-iam-policy "${APIGEE_APIM_GSA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --format="json" \
  --flatten="bindings[].members" \
  --filter="bindings.role:'roles/iam.workloadIdentityUser' AND bindings.members:'${WI_KSA_MEMBER}'" | grep -q "${WI_KSA_MEMBER}"; then
  gcloud iam service-accounts remove-iam-policy-binding \
    "${APIGEE_APIM_GSA_EMAIL}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="${WI_KSA_MEMBER}" \
    --project="${PROJECT_ID}" --quiet
  echo "✅ Workload Identity binding removed from GSA."
else
  echo "❕ Workload Identity binding not found for GSA. Skipping removal."
fi
echo ""

# Step 3: Remove IAM Permissions from Project for GSA
echo "🔄 Step 3: Removing IAM roles from project '$PROJECT_ID' for GSA '$APIGEE_APIM_GSA_EMAIL'..."
ROLES=(
  "roles/apigee.admin"
  "roles/networkservices.serviceExtensionsAdmin"
  "roles/compute.networkAdmin"
  "roles/compute.loadBalancerAdmin"
  "roles/iam.workloadIdentityUser" # This role might already be implicitly removed if GSA is deleted first, but explicit removal is safer.
)

for ROLE in "${ROLES[@]}"; do
  echo "Removing role '$ROLE'..."
  if gcloud projects get-iam-policy "${PROJECT_ID}" \
    --format="json" \
    --flatten="bindings[].members" \
    --filter="bindings.role:'$ROLE' AND bindings.members:'serviceAccount:$APIGEE_APIM_GSA_EMAIL'" | grep -q "$APIGEE_APIM_GSA_EMAIL"; then
    gcloud projects remove-iam-policy-binding "${PROJECT_ID}" \
      --member="serviceAccount:${APIGEE_APIM_GSA_EMAIL}" \
      --role="${ROLE}" \
      --project="${PROJECT_ID}" --quiet
    echo "✅ Role '$ROLE' removed."
  else
    echo "   ❕ Role '$ROLE' not found for GSA. Skipping removal."
  fi
done
echo "✅ All project-level IAM roles for GSA removed."
echo ""

# Step 4: Delete the Google Service Account (GSA)
echo "🔄 Step 4: Deleting Google Service Account '$APIGEE_APIM_GSA_EMAIL'..."
if gcloud iam service-accounts describe "$APIGEE_APIM_GSA_EMAIL" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud iam service-accounts delete "${APIGEE_APIM_GSA_EMAIL}" \
    --project="${PROJECT_ID}" --quiet
  echo "✅ GSA '$APIGEE_APIM_GSA_EMAIL' deleted."
else
  echo "❕ GSA '$APIGEE_APIM_GSA_EMAIL' does not exist. Skipping deletion."
fi
echo ""

echo "⚠️ Note: GCP services enabled by the original script (e.g., compute.googleapis.com) are generally project-wide settings and are not disabled by this cleanup script, as disabling them might impact other functionalities in your project."
echo ""
echo "✅ Cleanup complete: Apigee API Management Operator setup resources removed."

