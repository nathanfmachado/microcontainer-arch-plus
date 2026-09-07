#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="wordpress"

if [[ -z "${KUBECONFIG:-}" ]] && [[ -f "${HOME}/.kube/config" ]]; then
  export KUBECONFIG="${HOME}/.kube/config"
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERRO: kubectl nao encontrado."
  exit 1
fi

INGRESS_HOST="${INGRESS_HOST:-wordpress.local}"
TEST_URL="${TEST_URL:-}"

if [[ -z "${TEST_URL}" ]]; then
  if [[ "${INGRESS_HOST}" == "wordpress.local" ]]; then
    TEST_URL="http://localhost:30080"
  else
    TEST_URL="http://${INGRESS_HOST}"
  fi
fi

echo "==> URL de teste: ${TEST_URL}"
echo "==> PVCs antes do teste:"
kubectl -n "${NAMESPACE}" get pvc

echo ""
echo "==> Deletando pods WordPress e MySQL..."
kubectl -n "${NAMESPACE}" delete pod -l app=wordpress --ignore-not-found
kubectl -n "${NAMESPACE}" delete pod -l app=mysql --ignore-not-found

echo "==> Aguardando recriacao dos pods..."
kubectl -n "${NAMESPACE}" rollout status deployment/mysql --timeout=300s
kubectl -n "${NAMESPACE}" rollout status deployment/wordpress --timeout=300s

echo ""
echo "==> Pods apos recriacao:"
kubectl -n "${NAMESPACE}" get pods -o wide

echo ""
echo "==> Validando HTTP em ${TEST_URL}..."
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "${TEST_URL}" || echo "000")"

if [[ "${HTTP_CODE}" =~ ^(200|301|302)$ ]]; then
  echo "PASS: Site respondeu com HTTP ${HTTP_CODE} apos delecao dos pods."
  exit 0
fi

echo "FAIL: Site nao respondeu como esperado (HTTP ${HTTP_CODE})."
echo "Tente: TEST_URL=http://<IP>:30080 ./scripts/test-resilience.sh"
exit 1
