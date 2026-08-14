#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../confs/application.yaml.template"
REPO_URL="${REPO_URL:-}"

# verifie que l url github est fournie
if [ -z "$REPO_URL" ]; then
  echo "ERROR: set REPO_URL to your public GitHub repository URL"
  echo "example: REPO_URL=https://github.com/login/iot-p3.git sh /vagrant/scripts/deploy_app.sh"
  exit 1
fi

# verifie que le cluster et argocd sont disponibles
kubectl get namespace argocd >/dev/null
kubectl get namespace dev >/dev/null
kubectl get crd applications.argoproj.io >/dev/null

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

# genere l application argocd avec ton repo github
sed "s#__REPO_URL__#${REPO_URL}#g" "$TEMPLATE" > "$tmp_file"

# cree ou met a jour l application argocd
kubectl apply -f "$tmp_file"

# attend que argocd lise le repo et synchronise l app
kubectl wait -n argocd application/playground \
  --for=jsonpath='{.status.sync.status}'=Synced \
  --timeout=600s

kubectl wait -n argocd application/playground \
  --for=jsonpath='{.status.health.status}'=Healthy \
  --timeout=600s

kubectl get application playground -n argocd
kubectl get pods -n dev
