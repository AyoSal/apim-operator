#!/bin/bash
#Script to install helm charts for Apim CRDS and Apim Operator
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

echo ""
echo "🔄 1. Installing Apigee APIM CRDs with Helm..."
# Displaying the OCI chart path being used for clarity
CRD_CHART_PATH="oci://us-docker.pkg.dev/apigee-release/apigee-k8s-tooling-helm-charts/apigee-apim-operator-crds"

# Helm command for CRDs
helm install apigee-apim-crds -n "${KSA_NAMESPACE}" \
  "${CRD_CHART_PATH}" \
  --version 1.0.0 \
 --atomic 

# Check the exit status of the previous command
if [ $? -eq 0 ]; then
  echo "✅ Apigee APIM CRDs Helm installation initiated."
else
  echo "❌ Error: Apigee APIM CRDs Helm installation failed."
  exit 1 # Exit script on failure
fi

echo ""
echo "🔄 2. Installing Apigee APIM Operator with Helm..."

# Displaying the OCI chart path being used for clarity
OP_CHART_PATH="oci://us-docker.pkg.dev/apigee-release/apigee-k8s-tooling-helm-charts/apigee-apim-operator-helm"

# Helm command for Operator 
helm install apigee-apim-operator -n "${KSA_NAMESPACE}" \
  ${OP_CHART_PATH} \
  --version 1.0.0 \
  --set projectId="${PROJECT_ID}" \
  --set serviceAccount="${APIGEE_APIM_GSA_EMAIL}" \
  --set apigeeOrg="${PROJECT_ID}" \
  --set generateEnv=TRUE \
  --atomic # Ensures a clean rollback on failure

# Check the exit status of the previous command
if [ $? -eq 0 ]; then
  echo "✅ Apigee APIM Operator Helm installation initiated."
else
  echo "❌ Error: Apigee APIM Operator Helm installation failed."
  exit 1 # Exit script on failure
fi

echo "⚠️ IMPORTANT NEXT STEPS: ⚠️"
echo "1. Verify Helm releases status:"
echo "   helm list -n ${KSA_NAMESPACE}"
