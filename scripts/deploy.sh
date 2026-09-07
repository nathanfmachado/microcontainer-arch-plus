#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -z "${KUBECONFIG:-}" ]] && [[ -f "${HOME}/.kube/config" ]]; then
  export KUBECONFIG="${HOME}/.kube/config"
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERRO: kubectl nao encontrado. Execute scripts/install-k3s.sh primeiro."
  exit 1
fi

INGRESS_HOST="${INGRESS_HOST:-}"

if [[ -z "${INGRESS_HOST}" ]]; then
  if command -v curl >/dev/null 2>&1; then
    PUBLIC_IP="$(curl -sf ifconfig.me 2>/dev/null || curl -sf icanhazip.com 2>/dev/null || true)"
  else
    PUBLIC_IP=""
  fi

  if [[ -n "${PUBLIC_IP}" ]]; then
    INGRESS_HOST="${PUBLIC_IP}.nip.io"
    echo "==> Host do Ingress detectado: ${INGRESS_HOST}"
  else
    INGRESS_HOST="wordpress.local"
    echo "==> IP publico nao detectado. Usando host: ${INGRESS_HOST}"
    echo "    Adicione ao /etc/hosts: <IP_DA_VM> wordpress.local"
  fi
fi

# Copia toda a arvore k8s/ para preservar o caminho relativo ../../base do Kustomize.
TEMP_K8S="$(mktemp -d)"
trap 'rm -rf "${TEMP_K8S}"' EXIT

cp -R "${PROJECT_ROOT}/k8s/." "${TEMP_K8S}/"
sed -i.bak "s/host: wordpress.local/host: ${INGRESS_HOST}/" "${TEMP_K8S}/overlays/local/ingress-patch.yaml"
rm -f "${TEMP_K8S}/overlays/local/ingress-patch.yaml.bak"

echo "==> Aplicando manifests com Kustomize..."
kubectl apply -k "${TEMP_K8S}/overlays/local"

echo "==> Aguardando MySQL..."
kubectl -n wordpress rollout status deployment/mysql --timeout=300s

echo "==> Aguardando WordPress..."
kubectl -n wordpress rollout status deployment/wordpress --timeout=300s

echo ""
echo "==> Recursos no namespace wordpress:"
kubectl -n wordpress get all,pvc,ingress

echo ""
echo "Deploy concluido."
echo ""
echo "Acesso via Ingress:  http://${INGRESS_HOST}"
echo "Acesso via NodePort: http://<IP_DA_VM>:30080"
echo ""
echo "Exporte INGRESS_HOST=${INGRESS_HOST} para scripts/test-resilience.sh"
