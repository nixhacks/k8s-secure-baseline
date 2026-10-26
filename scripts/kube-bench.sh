#!/usr/bin/env bash
# Runs kube-bench in its own namespace (excluded from some Kyverno policies).
set -euo pipefail
OUT="${1:-kube-bench-report.txt}"
NS=kube-bench
BENCH_VERSION="${BENCH_VERSION:-v0.9.0}"   # pin a release you have verified
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$NS" delete job kube-bench --ignore-not-found
kubectl -n "$NS" apply -f "https://raw.githubusercontent.com/aquasecurity/kube-bench/${BENCH_VERSION}/job.yaml"
kubectl -n "$NS" wait --for=condition=complete job/kube-bench --timeout=180s \
  || { kubectl -n "$NS" logs job/kube-bench || true; exit 1; }
kubectl -n "$NS" logs job/kube-bench | tee "$OUT"
