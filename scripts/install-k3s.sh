#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando k3s no Ubuntu..."

if command -v k3s >/dev/null 2>&1; then
  echo "k3s ja esta instalado."
else
  curl -sfL https://get.k3s.io | sh -
fi

echo "==> Configurando kubectl para o usuario atual..."
mkdir -p "${HOME}/.kube"
sudo k3s kubectl config view --raw > "${HOME}/.kube/config"
chmod 600 "${HOME}/.kube/config"

export KUBECONFIG="${HOME}/.kube/config"

echo "==> Verificando cluster..."
kubectl get nodes
kubectl get storageclass

echo ""
echo "k3s instalado com sucesso."
echo "Use: export KUBECONFIG=${HOME}/.kube/config"
