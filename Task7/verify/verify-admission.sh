#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

expect_reject() {
  local manifest="$1"

  if kubectl apply -f "$manifest" >/dev/null 2>&1; then
    echo "ERROR: $manifest was accepted, but it must be rejected"
    kubectl delete -f "$manifest" --ignore-not-found >/dev/null 2>&1 || true
    return 1
  fi

  echo "OK: $manifest rejected"
}

kubectl apply -f 01-create-namespace.yaml >/dev/null

expect_reject insecure-manifests/01-privileged-pod.yaml
expect_reject insecure-manifests/02-hostpath-pod.yaml
expect_reject insecure-manifests/03-root-user-pod.yaml
