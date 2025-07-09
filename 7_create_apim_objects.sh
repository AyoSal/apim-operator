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
# Create API Product
# ---
cat <<EOF | kubectl apply -f -
apiVersion: apim.googleapis.com/v1
kind: APIProduct
metadata:
  name: api-product
  namespace: apim
spec:
  approvalType: auto
  description: Http bin GET calls for demo
  displayName: api-product
  enforcementRefs:
    - name: global-ext-lb1-apim-policy
      kind: APIMExtensionPolicy
      group: apim.googleapis.com
      namespace: apim
  attributes:
    - name: access
      value: private
EOF

echo "APIProduct 'api-product' created."

# ---
# Create Operation Set
# ---
cat <<EOF | kubectl apply -f -
apiVersion: apim.googleapis.com/v1
kind: APIOperationSet
metadata:
  name: item-set
  namespace: apim
spec:
  apiProductRefs:
    - name: api-product
      kind: APIProduct
      group: apim.googleapis.com
      namespace: apim
  quota:
    limit: 10
    interval: 1
    timeUnit: minute
  restOperations:
    - name: GetItems
      path: /get
      methods:
        - GET
    - name: GetOtherItems
      path: /headers
      methods:
        - GET
EOF

echo "APIOperationSet 'item-set' created."

echo "All specified Kubernetes objects have been applied."
