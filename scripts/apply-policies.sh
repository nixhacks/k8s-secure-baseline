#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Available deployment --all -n kyverno --timeout=180s
ok=0
for i in $(seq 1 20); do
  if kubectl apply -f policies/; then ok=1; break; fi
  echo "Kyverno webhook not ready, retry $i/20"; sleep 5
done
[ "$ok" = 1 ] || { echo "failed to apply policies"; exit 1; }
kubectl wait --for=condition=Ready clusterpolicy --all --timeout=120s
sleep 10
