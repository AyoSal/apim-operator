#!/bin/bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e # Exit immediately if a command exits with a non-zero status.

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: No PROJECT_ID variable set. Please set it (e.g., export PROJECT_ID=\"your-gcp-project-id\") and re-run."
  exit 1
fi

# Source default values
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/1_defaults_apim_operator.sh"

echo "Starting script to set up Apigee API Management Operator..."
echo "Using Project ID: $PROJECT_ID"
echo "GKE Cluster: $CLUSTER_NAME in $REGION"
echo "Apigee Organization: $APIGEE_ORG"

# Full GSA email
APIGEE_APIM_GSA_EMAIL="${APIGEE_APIM_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
# Workload Identity member format for KSA
WI_KSA_MEMBER="serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]"


echo ""
echo "🔄 1. Enabling required GCP services..."
SERVICES=(
  "compute.googleapis.com"
  "networkservices.googleapis.com"
  "container.googleapis.com"
  "apigee.googleapis.com" # Assuming this is required for Apigee Admin role
  "iam.googleapis.com" # For IAM operations, good practice to ensure it's enabled
)

for SERVICE in "${SERVICES[@]}"; do
  echo "Enabling $SERVICE..."
  if gcloud services enable "$SERVICE" --project="${PROJECT_ID}" --quiet; then
    echo "✅ $SERVICE enabled."
  else
    echo "   ❌ Failed to enable $SERVICE. Please check permissions or try again. Exiting."
    exit 1
  fi
done
echo "✅ All required GCP services are enabled."

echo ""
echo "🔄 2. Setting GCP project configuration to: $PROJECT_ID..."
gcloud config set project "${PROJECT_ID}"
echo "✅ GCP project set."

echo ""
echo "🔄 3. Creating Google Service Account (GSA) for APIM Operator: $APIGEE_APIM_GSA_NAME..."
if ! gcloud iam service-accounts describe "$APIGEE_APIM_GSA_EMAIL" --project="${PROJECT_ID}" &>/dev/null; then
  gcloud iam service-accounts create "${APIGEE_APIM_GSA_NAME}" \
    --project="${PROJECT_ID}" \
    --display-name="Service account for Apigee APIM Operator"
  echo "✅ Successfully created GSA: $APIGEE_APIM_GSA_EMAIL"
else
  echo "❕ GSA $APIGEE_APIM_GSA_EMAIL already exists. Skipping creation."
fi

echo ""
echo "🔄 4. Providing IAM Permissions to GSA: $APIGEE_APIM_GSA_EMAIL..."
ROLES=(
  "roles/apigee.admin"
  "roles/networkservices.serviceExtensionsAdmin"
  "roles/compute.networkAdmin"
  "roles/compute.loadBalancerAdmin"
  "roles/iam.workloadIdentityUser" # Allows the GSA to be impersonated by a KSA
)

for ROLE in "${ROLES[@]}"; do
  echo "Granting role '$ROLE'..."
  # Check if the binding already exists to make it idempotent
  if ! gcloud projects get-iam-policy "${PROJECT_ID}" \
    --format="json" \
    --flatten="bindings[].members" \
    --filter="bindings.role:'$ROLE' AND bindings.members:'serviceAccount:$APIGEE_APIM_GSA_EMAIL'" | grep -q "$APIGEE_APIM_GSA_EMAIL"; then
    gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
      --member="serviceAccount:${APIGEE_APIM_GSA_EMAIL}" \
      --role="${ROLE}" \
      --condition=None \
      --project="${PROJECT_ID}"
    echo "✅ Role '$ROLE' granted."
  else
    echo "   ❕ Role '$ROLE' already granted. Skipping."
  fi
done
echo "✅ All required IAM roles provided to GSA."

echo ""
echo "🔄 5. Binding Kubernetes Service Account (KSA) with Google Service Account (GSA) for Workload Identity..."
echo "   KSA: ${KSA_NAMESPACE}/${KSA_NAME} will be bound to GSA: ${APIGEE_APIM_GSA_EMAIL}"
# This binding allows the KSA to impersonate the GSA
if ! gcloud iam service-accounts get-iam-policy "${APIGEE_APIM_GSA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --format="json" \
  --flatten="bindings[].members" \
  --filter="bindings.role:'roles/iam.workloadIdentityUser' AND bindings.members:'${WI_KSA_MEMBER}'" | grep -q "${WI_KSA_MEMBER}"; then
  gcloud iam service-accounts add-iam-policy-binding \
    "${APIGEE_APIM_GSA_EMAIL}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="${WI_KSA_MEMBER}" \
    --project="${PROJECT_ID}"
  echo "✅ KSA bound to GSA for Workload Identity."
else
  echo "❕ KSA already bound to GSA. Skipping binding."
fi

echo ""
echo "🔄 6. Creating Kubernetes namespace: $KSA_NAMESPACE..."
if ! kubectl get ns "${KSA_NAMESPACE}" &>/dev/null; then
  kubectl create ns "${KSA_NAMESPACE}"
  echo "✅ Namespace '${KSA_NAMESPACE}' created."
else
  echo "❕ Namespace '${KSA_NAMESPACE}' already exists. Skipping creation."
fi

echo "--------------------------------------------------"
echo " 🎉 Apigee API Management Operator setup script completed!"
echo " Google Service Account: $APIGEE_APIM_GSA_EMAIL"
echo " Kubernetes Service Account: ${KSA_NAMESPACE}/${KSA_NAME}"
echo "--------------------------------------------------"
echo "2. Check pod status in the '${KSA_NAMESPACE}' namespace:"
echo "   kubectl get pods -n ${KSA_NAMESPACE}"
echo "3. Ensure your Kubernetes Service Account '${KSA_NAME}' has the Workload Identity annotation:"
echo "   iam.gke.io/gcp-service-account: $APIGEE_APIM_GSA_EMAIL"
echo "   If the KSA is not automatically created by the Helm chart with this annotation, you might need to apply it manually."
echo "4. Monitor the Apigee Operator logs for any issues."
#!/bin/bash


