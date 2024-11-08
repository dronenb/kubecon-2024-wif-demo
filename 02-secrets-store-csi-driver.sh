#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

source ./demo-magic.sh
pe "bat --paging=never  opentofu/02-*"
cd kubernetes/02-secrets-store-csi-driver/manifests/overlays/minikube
pe "kubectl kustomize | kubectl apply -f -"
pe "kubectl wait --for=condition=Ready -n default pod/secrets-demo"
pe "kubectl exec -it pod/secrets-demo  -- cat "