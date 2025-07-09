#!/bin/bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

#export GATEWAY_IP_ADDRESS=$(kubectl get gateways.gateway.networking.k8s.io global-ext-bin -o=jsonpath="{.status.addresses[0].value}")
export GATEWAY_IP_ADDRESS="DUMMY IP ADDRESS"
# --- Prerequisites and Variable Checks ---

# Ensure kubectl is installed and configured
if ! command -v kubectl &> /dev/null
then
    echo "❌ Error: kubectl command not found. Please install kubectl and ensure it's in your PATH."
    exit 1
fi

# Check if GATEWAY_IP_ADDRESS is set. This variable should come from your GCE Load Balancer creation script.
if [ -z "$GATEWAY_IP_ADDRESS" ]; then
  echo "❌ Error: No GATEWAY_IP_ADDRESS variable set."
  echo "Please set it (e.g., export GATEWAY_IP_ADDRESS=\"YOUR_LOAD_BALANCER_IP\") and re-run."
  exit 1
fi

echo "Starting script to deploy Kubernetes Gateway API objects..."
echo "Using GATEWAY_IP_ADDRESS: $GATEWAY_IP_ADDRESS"
echo "The HTTPRoute hostname will be: $GATEWAY_IP_ADDRESS.nip.io"
echo ""


# --- 2. Deploy httpbin Kubernetes application (Namespace, ServiceAccount, Service, Deployment) ---
echo "🔄 2. Applying httpbin application (Namespace, ServiceAccount, Service, Deployment)..."
cat <<EOF | kubectl apply -f -
# target.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: http
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  namespace: http
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: http
  labels:
    app: httpbin
    service: httpbin
spec:
  # Using ClusterIP instead of LoadBalancer type, as the traffic will come from the Gateway API
  # The original Service type LoadBalancer would create a separate GCP Load Balancer for the service itself,
  # which is not needed when using Gateway API for external exposure.
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: http
spec:
  replicas: 3
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      serviceAccountName: httpbin
      containers:
        - image: docker.io/kennethreitz/httpbin
          imagePullPolicy: IfNotPresent
          name: httpbin
          ports:
            - containerPort: 80
EOF
echo "✅ httpbin application applied."
echo ""

# --- 1. Deploy Kubernetes Gateway ---
echo "🔄 1. Applying Kubernetes Gateway (global-ext-bin)..."
cat <<EOF | kubectl apply -f -
# gateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: global-ext-bin
  namespace: default
spec:
  gatewayClassName: gke-l7-global-external-managed
  listeners:
    - name: http
      protocol: HTTP
      allowedRoutes:
        kinds:
          - kind: HTTPRoute
        namespaces:
          from: All
      port: 80
EOF
echo "✅ Kubernetes Gateway applied."
echo ""

# --- 3. Deploy Kubernetes HTTPRoute ---
echo "🔄 3. Applying Kubernetes HTTPRoute (http-bin-route)..."
cat <<EOF | kubectl apply -f -
# httproute.yaml
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: http-bin-route
  namespace: http
spec:
  parentRefs:
    - kind: Gateway
      name: global-ext-bin
      namespace: default
  hostnames:
    - "$GATEWAY_IP_ADDRESS.nip.io" # Dynamically injecting the external IP
  rules:
    - matches:
        - path:
            value: /
      backendRefs:
        - name: httpbin
          kind: Service
          port: 80
          namespace: http
EOF
echo "✅ Kubernetes HTTPRoute applied."
echo ""

echo "--------------------------------------------------"
echo " 🎉 Kubernetes Gateway API objects deployed!"
echo " It may take a few minutes for the Gateway to reconcile and traffic to flow."
echo " Access your httpbin service via the Gateway at: http://$GATEWAY_IP_ADDRESS.nip.io"
echo "--------------------------------------------------"
echo "To verify the Gateway status, you can use:"
echo "  kubectl get gateway global-ext-bin -n default"
echo "To verify the HTTPRoute status, you can use:"
echo "  kubectl get httproute http-bin-route -n http"
#!/bin/bash


