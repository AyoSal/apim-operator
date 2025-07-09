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

set -e

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: No PROJECT_ID variable set. Please set it and re-run."
  exit 1
fi

# Source default values (assuming you have a defaults.sh for GKE as well)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# You'll need to create a defaults_gke.sh with variables like CLUSTER_NAME, ZONE, MACHINE_TYPE
source "$SCRIPT_DIR/1_defaults_apim_operator.sh"

echo "Starting script to create GKE Cluster..."
echo "Using Project ID: $PROJECT_ID"
echo "Cluster Name: $CLUSTER_NAME"
echo "Zone: $ZONE"

echo ""
echo "🔄 1. Creating GKE Cluster: $CLUSTER_NAME in $ZONE..."
echo "Kubernetes Gateway API and Workload Identity are enabled on the GKE Cluster: $CLUSTER_NAME"
gcloud container clusters create $CLUSTER_NAME \
   --zone="$ZONE" \
   --workload-pool=${PROJECT_ID}.svc.id.goog \
   --machine-type="$MACHINE_TYPE" \
   --gateway-api=standard
echo "✅ GKE Cluster creation initiated. This may take a few minutes."

echo ""
echo "🔄 2. Getting GKE Cluster credentials for $CLUSTER_NAME..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE"
echo "✅ Successfully retrieved cluster credentials."
echo "--------------------------------------------------"
echo " 🎉GKE Cluster configured!"
echo " Cluster Name: $CLUSTER_NAME"
echo " Zone: $ZONE"
echo " To connect to your cluster, ensure you have kubectl installed and run:"
echo "   gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID"
echo "--------------------------------------------------"
echo "⚠️ IMPORTANT NOTES: ⚠️"
echo "1. Cluster provisioning can take several minutes. You can check the status with:"
echo "gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID"
echo "2. Once the cluster is up, you can deploy your applications using kubectl."
