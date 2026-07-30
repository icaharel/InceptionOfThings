#!/bin/sh
set -eu

SERVER_IP="192.168.56.110"
WORKER_IP="192.168.56.111"
TOKEN_FILE="/vagrant/confs/node-token"

apt-get update
apt-get install -y curl

PRIVATE_IFACE="$(ip -o -4 addr show | grep "$WORKER_IP" | cut -d ' ' -f 2)"

until [ -s "$TOKEN_FILE" ]; do
  echo "Waiting for K3s server token..."
  sleep 2
done

K3S_TOKEN="$(cat "$TOKEN_FILE")"

curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="$K3S_TOKEN" INSTALL_K3S_EXEC="agent --node-ip=${WORKER_IP} --flannel-iface=${PRIVATE_IFACE}" sh -
