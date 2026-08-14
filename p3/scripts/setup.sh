#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CURRENT_USER="${USER:-$(id -un)}"

# installe les outils necessaires dans la vm
sh "$SCRIPT_DIR/install_tools.sh"

# continue avec le groupe docker si la session ne le voit pas encore
if [ "$(id -u)" -ne 0 ] \
  && ! docker info >/dev/null 2>&1 \
  && command -v sg >/dev/null 2>&1 \
  && id -nG "$CURRENT_USER" | tr ' ' '\n' | grep -qx docker; then
  echo "Current shell cannot access Docker yet; continuing with sg docker."
  sg docker -c "sh '$SCRIPT_DIR/create_cluster.sh' && sh '$SCRIPT_DIR/install_argocd.sh'"
else
  sh "$SCRIPT_DIR/create_cluster.sh"
  sh "$SCRIPT_DIR/install_argocd.sh"
fi

echo "P3 infrastructure is ready."
