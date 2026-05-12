#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

kubectl apply -f 01-create-namespace.yaml

if ! kubectl get crd constrainttemplates.templates.gatekeeper.sh >/dev/null 2>&1; then
  echo "ERROR: OPA Gatekeeper is not installed in the current cluster"
  echo "Install Gatekeeper before applying Task7/gatekeeper manifests"
  exit 1
fi

# Создаем ограничения Gatekeeper
kubectl apply -f gatekeeper/constraint-templates/
sleep 5
kubectl apply -f gatekeeper/constraints/

# Запускаем безопасные поды
kubectl apply -f secure-manifests/

# Проверяем, что ограничения Gatekeeper применились и поды запустились
kubectl get constrainttemplates
kubectl get k8sdenyprivileged
kubectl get k8sdenyhostpath
kubectl get k8srequirerunasnonroot
kubectl get pods -n audit-zone
