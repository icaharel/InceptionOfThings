#!/bin/sh
set -eu

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/confs/node-token"
KUBECONFIG_FILE="/vagrant/confs/k3s.yaml"

apt-get update
apt-get install -y curl

PRIVATE_IFACE="$(ip -o -4 addr show | grep "$SERVER_IP" | cut -d ' ' -f 2)"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --advertise-address=${SERVER_IP} --flannel-iface=${PRIVATE_IFACE} --write-kubeconfig-mode=644" sh -

until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

mkdir -p /vagrant/confs
cp /var/lib/rancher/k3s/server/node-token "$TOKEN_FILE"
cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_FILE"
sed -i "s/127.0.0.1/${SERVER_IP}/g" "$KUBECONFIG_FILE"

kubectl get nodes
