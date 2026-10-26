#!/usr/bin/env bash
# Disable token auto-mount on default ServiceAccounts in namespaces we own.
set -euo pipefail
for ns in default secure-apps; do
  for i in $(seq 1 30); do
    kubectl get sa default -n "$ns" >/dev/null 2>&1 && break
    sleep 1
  done
  kubectl patch sa default -n "$ns" -p '{"automountServiceAccountToken": false}'
done
