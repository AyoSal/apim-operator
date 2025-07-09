# defaults_apim_operator.sh
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


# === GCP Project and GKE Cluster Details ===
# PROJECT_ID should be set as an environment variable before running the script.
export PROJECT_ID="YOUR PROJECT ID"
CLUSTER_NAME="YOUR CLUSTER NAME" # Your GKE cluster name
REGION="YOUR CLUSTER REGION"          # The region where your GKE cluster is located (e.g., us-central1)
ZONE="YOUR CLUSTER ZONE"
MACHINE_TYPE="e2-medium"

# === Apigee Organization Details ===
# APIGEE_ORG is often the same as PROJECT_ID for simplicity, but can be different.
export APIGEE_ORG="${PROJECT_ID}" # Your Apigee organization ID

# === Service Account Names ===
export APIGEE_APIM_GSA_NAME="apigee-apim-gsa" # Name for the Google Service Account for APIM Operator
export KSA_NAMESPACE="apim"                   # Kubernetes namespace for the APIM Operator KSA
export KSA_NAME="apim-ksa"                    # Kubernetes Service Account name for APIM Operator
export APIGEE_APIM_GSA_EMAIL="apigee-apim-gsa@$PROJECT_ID.iam.gserviceaccount.com"

# These paths are examples and MUST be updated to your actual file locations.
export APIM_CRDS_HELM_CHART_PATH="oci://us-docker.pkg.dev/apigee-release/apigee-k8s-tooling-helm-charts/apigee-apim-operator-crds"
export APIM_OPERATOR_HELM_CHART_PATH="oci://us-docker.pkg.dev/apigee-release/apigee-k8s-tooling-helm-charts/apigee-apim-operator-helm"

# Helm Chart Versions (ensure these match your .tgz file versions)
export APIM_CRDS_HELM_VERSION="1.0.0"
export APIM_OPERATOR_HELM_VERSION="1.0.0"

# === Apigee Operator Specific Settings ===
export APIGEE_MGMT_URL="https://autopush-apigee.sandbox.googleapis.com" # Apigee Management API URL
# Controller Image (ensure this matches the image you intend to use)
CONTROLLER_IMAGE="us-west1-docker.pkg.dev/apim-operator-bootcamp-20/apim-operator-testing/apim-operator:20771_90de6d012"
#!/bin/bash


