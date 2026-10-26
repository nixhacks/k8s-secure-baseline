#!/usr/bin/env bash
# Asserts that bad pods are rejected and the good pod is accepted.
set -u
fail=0

expect_reject() {  # file, namespace, description
  if kubectl apply --dry-run=server -n "$2" -f "$1" >/dev/null 2>&1; then
    echo "FAIL: $3 was ACCEPTED in $2"; fail=1
  else
    echo "PASS: $3 rejected in $2"
  fi
}
expect_accept() {
  if kubectl apply --dry-run=server -n "$2" -f "$1" >/dev/null 2>&1; then
    echo "PASS: $3 accepted in $2"
  else
    echo "FAIL: $3 was REJECTED in $2"; kubectl apply --dry-run=server -n "$2" -f "$1" || true; fail=1
  fi
}

# Kyverno layer (default namespace has no PSA enforcement)
expect_reject manifests/test-bad-privileged.yaml default "privileged pod (Kyverno)"
expect_reject manifests/test-bad-hostpath.yaml   default "hostPath pod (Kyverno)"
expect_reject manifests/test-bad-latest.yaml     default ":latest pod (Kyverno)"
# Pod Security Admission layer
expect_reject manifests/test-bad-privileged.yaml secure-apps "privileged pod (PSA)"
expect_reject manifests/test-bad-hostpath.yaml   secure-apps "hostPath pod (PSA)"
# Good pod passes both layers
expect_accept manifests/test-good-pod.yaml secure-apps "hardened pod"
expect_accept manifests/test-good-pod.yaml default "hardened pod"

exit $fail
