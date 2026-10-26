# k8s-secure-baseline

[![baseline](https://github.com/nixhacks/k8s-secure-baseline/actions/workflows/baseline.yml/badge.svg)](https://github.com/nixhacks/k8s-secure-baseline/actions/workflows/baseline.yml)

A small, reproducible Kubernetes hardening baseline on `kind`, with automated tests that prove bad workloads get rejected.

## Threat model (short)
- **Adversary:** a developer or compromised CI identity that can create pods in the cluster.
- **Goal:** break out to the node (privileged container, hostPath), pull untrusted images, or move laterally over the network.
- **Controls:** Pod Security Admission (`restricted`), Kyverno admission policies, default-deny NetworkPolicy.
- **Out of scope (see later labs):** runtime detection (Falco/Tetragon), image signing, workload identity.

## Layers
| Layer | What it does | Where |
|---|---|---|
| Pod Security Admission | Enforces `restricted` in `secure-apps` | `manifests/00-namespace.yaml` |
| Kyverno | Blocks privileged, hostPath, unapproved registries, `:latest` cluster-wide | `policies/` |
| NetworkPolicy | Default deny, DNS egress only | `manifests/10-networkpolicy.yaml` |

## Run it (about 10 minutes)
Requires: docker, kind, kubectl, helm.

    make all        # cluster + Kyverno + policies + tests
    make bench      # kube-bench report into reports/
    make down

Expected `make verify` output: 5 rejections and 2 acceptances, all `PASS`.

## Caveats (be honest in your write-up)
- kube-bench on kind reports many control-plane checks as unavailable or FAIL because kind is not a hardened distro. Treat it as a learning artifact; record the findings you fixed and the ones that don't apply.
- kind's default CNI enforcement of NetworkPolicy depends on the kind version; Lab 3 swaps in Cilium for guaranteed enforcement. Add a test that proves a blocked connection.
- Pin and verify versions (Kyverno chart, kube-bench) before publishing.

## Next steps
Falco/Tetragon rules, cosign signature verification with Kyverno `verifyImages`, Cilium network policy tests.

## Results

### Admission controls (tested in CI on every push)
| Test | Namespace | Result | Blocked by |
|---|---|---|---|
| privileged pod | default | rejected | Kyverno `disallow-privileged-containers` |
| hostPath pod | default | rejected | Kyverno `disallow-hostpath` |
| `:latest` image | default | rejected | Kyverno `disallow-latest-tag` |
| privileged pod | secure-apps | rejected | Pod Security Admission `restricted` |
| hostPath pod | secure-apps | rejected | Pod Security Admission `restricted` |
| hardened pod | secure-apps, default | accepted | n/a |

PSA's rejection of the privileged pod listed five violations at once (privileged, allowPrivilegeEscalation, capabilities, runAsNonRoot, seccompProfile), which shows what `restricted` demands beyond "not privileged".

### Findings
- **Network isolation is unproven.** With default-deny applied in `secure-apps`, a pod could still reach the API server. Default kind networking did not enforce NetworkPolicy in my test. The policies exist and are correct; enforcement needs a CNI that implements them (next lab: Cilium).
- **kube-bench baseline (kind): 16 PASS, 8 FAIL, 35 WARN.** Reports are in `docs/`. Treat the numbers as indicative, since kind is not a hardened distribution.

| Check | Status |
|---|---|
| 4.1.1, 4.1.9 (kubelet file permissions) | Not applicable: kind nodes are containers built from kind's image |
| 5.1.5, 5.1.6 (default ServiceAccounts) | Fixed in `default` and `secure-apps`; still failing in system namespaces, which need their tokens |
| 5.1.1 to 5.1.4 (cluster-admin, secrets, wildcards, pod create) | Not yet triaged |

- **Documented policy exception:** the `kube-bench` namespace is excluded from the hostPath, registry and latest-tag policies, because the tool needs hostPath and pulls from docker.io. The exception is scoped to that one namespace.
- **CI scope:** the kube-bench step is informational (`continue-on-error`). The build gate is the admission-control test.

### Lessons learned
- Kyverno's webhook needs time to become ready; applying policies right after install fails intermittently. `scripts/apply-policies.sh` waits and retries.
- A new namespace's `default` ServiceAccount is created asynchronously. Declaring it in a manifest raced with the controller on a fresh cluster. `scripts/harden-default-sa.sh` waits for it and patches instead.
