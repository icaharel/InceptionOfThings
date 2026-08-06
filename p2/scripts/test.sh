#!/bin/sh
set -eu

VM_NAME="icaharelS"
SERVER_IP="192.168.56.110"

run_in_vm() {
  vagrant ssh "$VM_NAME" -c "$1"
}

check_http() {
  host="$1"
  expected="$2"

  response="$(curl -s -H "Host: ${host}" "http://${SERVER_IP}")"

  if [ "$response" = "$expected" ]; then
    echo "OK: ${host} returns ${expected}"
  else
    echo "ERROR: ${host} returned '${response}', expected '${expected}'"
    exit 1
  fi
}

echo "Checking VM status..."
vagrant status "$VM_NAME" | grep -q "running"

echo "Checking Kubernetes node..."
run_in_vm "kubectl get nodes | grep -q ' Ready '"

echo "Checking deployments..."
run_in_vm "kubectl get deployment app1 app2 app3"

echo "Checking services..."
run_in_vm "kubectl get service app1 app2 app3"

echo "Checking app2 replicas..."
ready_replicas="$(vagrant ssh "$VM_NAME" -c "kubectl get deployment app2 -o jsonpath='{.status.readyReplicas}'" 2>/dev/null | tr -d '\r')"
if [ "$ready_replicas" != "3" ]; then
  echo "ERROR: app2 has ${ready_replicas:-0} ready replicas, expected 3"
  exit 1
fi
echo "OK: app2 has 3 ready replicas"

echo "Checking ingress..."
run_in_vm "kubectl get ingress apps-ingress"

echo "Checking HTTP routing..."
check_http "app1.com" "app1"
check_http "app2.com" "app2"
check_http "random.com" "app3"

echo "All P2 checks passed."
