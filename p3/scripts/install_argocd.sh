#!/bin/sh
set -eu

CLUSTER_NAME="${CLUSTER_NAME:-iot-p3}"

# charge une image dans les nodes k3d
import_image_into_nodes() {
  image="$1"
  image_archive="$(mktemp)"

# tire l image avec docker dans la vm
  docker pull "$image"
  docker save "$image" -o "$image_archive"

# copie l image dans chaque node k3d
  docker ps --format '{{.Names}}' \
    | grep -E "^k3d-${CLUSTER_NAME}-(server|agent)-" \
    | while IFS= read -r node; do
        docker cp "$image_archive" "$node:/tmp/k3d-image.tar"
        docker exec "$node" ctr images import /tmp/k3d-image.tar
        docker exec "$node" rm -f /tmp/k3d-image.tar
      done

  rm -f "$image_archive"
}

# cree les namespaces necessaires
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

# installe argocd avec un apply cote serveur
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# evite de retirer les images si elles sont deja chargees
for deployment in \
  argocd-applicationset-controller \
  argocd-dex-server \
  argocd-notifications-controller \
  argocd-redis \
  argocd-repo-server \
  argocd-server; do
  kubectl patch deployment "$deployment" -n argocd --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'
  if kubectl get deployment "$deployment" -n argocd -o jsonpath='{.spec.template.spec.initContainers[0].name}' | grep -q .; then
    kubectl patch deployment "$deployment" -n argocd --type=json \
      -p='[{"op":"replace","path":"/spec/template/spec/initContainers/0/imagePullPolicy","value":"IfNotPresent"}]'
  fi
done

kubectl patch statefulset argocd-application-controller -n argocd --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'
if kubectl get statefulset argocd-application-controller -n argocd -o jsonpath='{.spec.template.spec.initContainers[0].name}' | grep -q .; then
  kubectl patch statefulset argocd-application-controller -n argocd --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/initContainers/0/imagePullPolicy","value":"IfNotPresent"}]'
fi

# precharge les images argocd dans les nodes k3d
kubectl get deployment,statefulset -n argocd \
  -o jsonpath='{range .items[*].spec.template.spec.initContainers[*]}{.image}{"\n"}{end}{range .items[*].spec.template.spec.containers[*]}{.image}{"\n"}{end}' \
  | sort -u \
  | while IFS= read -r image; do
      if [ -n "$image" ]; then
        import_image_into_nodes "$image"
      fi
    done

# attend que tous les composants argocd soient prets
kubectl wait --for=condition=available --timeout=1200s deployment --all -n argocd
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=1200s

# affiche l etat du cluster et des namespaces
kubectl get namespaces
kubectl get pods -n argocd
kubectl get pods -n dev

# affiche le mot de passe initial argocd
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
echo "Run this command to open Argo CD locally:"
echo "kubectl port-forward svc/argocd-server -n argocd 8081:443"
echo "Then browse: https://localhost:8081"
