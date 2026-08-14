#!/bin/sh
set -eu

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

CURRENT_USER="${USER:-$(id -un)}"

# verifie si l utilisateur a deja le groupe docker
user_has_docker_group() {
  id -nG "$CURRENT_USER" | tr ' ' '\n' | grep -qx docker
}

# lance une commande en root seulement si necessaire
run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [ "$(uname -s)" != "Linux" ]; then
  echo "ERROR: this script is intended to run inside a Linux VM."
  exit 1
fi

# installe les paquets de base sur ubuntu ou debian
if need_cmd apt-get; then
  run_as_root apt-get update
  run_as_root apt-get install -y bash ca-certificates curl git
else
  echo "ERROR: apt-get was not found. Use a Debian/Ubuntu based VM for this setup."
  exit 1
fi

# installe docker si la commande est absente
if ! need_cmd docker; then
  curl -fsSL https://get.docker.com | run_as_root sh
fi

# demarre docker selon le systeme disponible
if ! docker info >/dev/null 2>&1; then
  run_as_root systemctl start docker >/dev/null 2>&1 || true
  run_as_root service docker start >/dev/null 2>&1 || true
fi

# ajoute l utilisateur au groupe docker si besoin
if [ "$(id -u)" -ne 0 ] && ! user_has_docker_group; then
  run_as_root usermod -aG docker "$CURRENT_USER"
  echo "Docker group added for $CURRENT_USER."
  echo "You may need to reconnect to the VM or run: newgrp docker"
fi

# detecte l architecture pour telecharger le bon binaire
case "$(uname -m)" in
  x86_64 | amd64)
    ARCH="amd64"
    ;;
  aarch64 | arm64)
    ARCH="arm64"
    ;;
  *)
    echo "ERROR: unsupported CPU architecture: $(uname -m)"
    exit 1
    ;;
esac

# permet de lancer l image playground amd64 sur une vm arm64
if [ "$ARCH" = "arm64" ]; then
  run_as_root apt-get install -y qemu-user-static binfmt-support
  if need_cmd docker && docker info >/dev/null 2>&1; then
    docker run --privileged --rm tonistiigi/binfmt --install amd64
  fi
fi

# installe kubectl si absent ou inutilisable
if ! need_cmd kubectl || ! kubectl version --client=true >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSLo "$tmp_dir/kubectl" "https://dl.k8s.io/release/${kubectl_version}/bin/linux/${ARCH}/kubectl"
  chmod +x "$tmp_dir/kubectl"
  run_as_root mv "$tmp_dir/kubectl" /usr/local/bin/kubectl
  rmdir "$tmp_dir"
fi

# installe k3d si absent
if ! need_cmd k3d; then
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | run_as_root bash
fi

# affiche les versions installees
echo "Installed tools:"
docker --version
kubectl version --client=true
k3d version
