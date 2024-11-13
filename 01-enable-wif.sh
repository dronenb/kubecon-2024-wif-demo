#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

source ./demo-magic.sh
pe "bat --paging=never  opentofu/01-enable-wif.tf"

pe "minikube start 
    --extra-config=apiserver.service-account-issuer=https://storage.googleapis.com/dronenb-kubecon-2024-demo
    --extra-config=apiserver.service-account-jwks-uri=https://storage.googleapis.com/dronenb-kubecon-2024-demo/openid/v1/jwks"
# I have seen this happen:
# error: failed to create token: serviceaccounts "default" not found
# Sleep for a few seconds so it doesn't
sleep 2
pe "kubectl create token --namespace default default | jc --jwt -p"
pe "kubectl get --raw /.well-known/openid-configuration | gcloud storage cp --cache-control=no-cache /dev/stdin gs://dronenb-kubecon-2024-demo/.well-known/openid-configuration"
pe "kubectl get --raw /openid/v1/jwks | gcloud storage cp --cache-control=no-cache /dev/stdin gs://dronenb-kubecon-2024-demo/openid/v1/jwks"
pe "bat --paging=never opentofu/01-enable-wif-aws.tf opentofu/01-enable-wif-azure.tf opentofu/01-enable-wif-gcp.tf"
