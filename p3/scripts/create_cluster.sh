#!/bin/sh
set -eu

CLUSTER_NAME="${CLUSTER_NAME:-iot-p3}"
RESET_CLUSTER="${RESET_CLUSTER:-0}"

# verifie que docker est installe
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed."
  exit 1
fi

# verifie que docker est accessible par l utilisateur
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: docker is not running or current user cannot access it."
  echo "Try reconnecting to the VM, running 'newgrp docker', or starting Docker."
  exit 1
fi

# verifie que k3d est installe
if ! command -v k3d >/dev/null 2>&1; then
  echo "ERROR: k3d is not installed."
  exit 1
fi

# reutilise le cluster si il existe deja
if k3d cluster list | awk 'NR > 1 {print $1}' | grep -qx "$CLUSTER_NAME"; then
  if [ "$RESET_CLUSTER" = "1" ]; then
    k3d cluster delete "$CLUSTER_NAME"
  else
    kubectl config use-context "k3d-${CLUSTER_NAME}"
    kubectl cluster-info
    kubectl get nodes
    echo "Cluster $CLUSTER_NAME already exists. Set RESET_CLUSTER=1 to recreate it."
    exit 0
  fi
fi

# cree un cluster k3s dans docker avec un agent
k3d cluster create "$CLUSTER_NAME" \
  --agents 1 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer"

# selectionne le contexte kubectl du cluster
kubectl config use-context "k3d-${CLUSTER_NAME}"
kubectl cluster-info
kubectl get nodes
