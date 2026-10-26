#!/usr/bin/env bash
# Runs kube-bench as a Job and saves the report. Usage: scripts/kube-bench.sh [outfile]
set -euo pipefail
OUT="${1:-kube-bench-report.txt}"
BENCH_VERSION="${BENCH_VERSION:-v0.9.0}"   # pin a release you have verified
kubectl delete job kube-bench --ignore-not-found
kubectl apply -f "https://raw.githubusercontent.com/aquasecurity/kube-bench/${BENCH_VERSION}/job.yaml"
kubectl wait --for=condition=complete job/kube-bench --timeout=180s
kubectl logs job/kube-bench | tee "$OUT"
