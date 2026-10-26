# k8s-secure-baseline

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
