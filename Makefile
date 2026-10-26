KYVERNO_CHART_VERSION ?= 3.2.6   # pin; verify with: helm search repo kyverno/kyverno --versions

.PHONY: up kyverno apply verify bench down all
all: up kyverno apply verify

up:
	kind create cluster --config kind-config.yaml

kyverno:
	helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null
	helm repo update >/dev/null
	helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace \
	  --version $(KYVERNO_CHART_VERSION) --wait --timeout 5m

apply:
	kubectl apply -f manifests/00-namespace.yaml -f manifests/10-networkpolicy.yaml
	kubectl apply -f policies/
	sleep 10   # let Kyverno register webhooks for new policies

verify:
	./scripts/verify.sh

bench:
	./scripts/kube-bench.sh reports/kube-bench-$$(date +%F).txt

down:
	kind delete cluster --name secure-baseline
