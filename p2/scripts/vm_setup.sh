#!/bin/sh
set -eu

SERVER_IP="192.168.56.110"
apt-get update
apt-get install -y curl

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --advertise-address=${SERVER_IP} --write-kubeconfig-mode=644" sh -

until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

until kubectl get nodes | grep -q " Ready "; do
  sleep 2
done

kubectl apply -f /vagrant/pods/
kubectl apply -f /vagrant/ingress/
kubectl get nodes
kubectl get pods
kubectl get services
kubectl get ingress
