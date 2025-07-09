#!/bin/bash
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
# ---
# This script creates An APIMExtensionPolicy named 'global-ext-lb1-apim-policy'

#
# It uses 'kubectl apply -f -' with heredoc syntax to apply each YAML definition.
# Ensure you have kubectl configured and connected to your Kubernetes cluster.
# ---

echo "Applying APIMExtensionPolicy: global-ext-lb1-apim-policy.yaml"
# Define and apply the APIMExtensionPolicy
kubectl apply -f - <<EOF
apiVersion: apim.googleapis.com/v1
kind: APIMExtensionPolicy
metadata:
  name: global-ext-lb1-apim-policy
  namespace: apim
spec:
  location: global
  failOpen: false
  timeout: 1000ms
  defaultSecurityEnabled: true
  targetRef: # identifies the Gateway where the extension must be applied
    name: global-ext-lb1
    kind: Gateway
    namespace: default
EOF
echo "APIMExtensionPolicy applied successfully."
#!/bin/bash
