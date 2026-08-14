#!/bin/sh
set -eu

APP_NAMESPACE="${APP_NAMESPACE:-dev}"
APP_NAME="${APP_NAME:-playground}"
LOCAL_PORT="${LOCAL_PORT:-8888}"

# attend que le deployment de l app soit pret
kubectl rollout status "deployment/${APP_NAME}" -n "$APP_NAMESPACE" --timeout=300s

# affiche l etat kubernetes de l app
kubectl get deployment,service,ingress,pods -n "$APP_NAMESPACE"

log_file="$(mktemp)"
trap 'kill "$pf_pid" >/dev/null 2>&1 || true; rm -f "$log_file"' EXIT

# ouvre un acces local vers le service de l app
kubectl port-forward -n "$APP_NAMESPACE" "service/${APP_NAME}" "${LOCAL_PORT}:8888" > "$log_file" 2>&1 &
pf_pid="$!"
sleep 3

# appelle l app via le port local
curl -fsS "http://127.0.0.1:${LOCAL_PORT}"
echo
