#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob

source ./demo-magic.sh
pe "bat --paging=never opentofu/02-*"
cd kubernetes/02-secrets-store-csi-driver/manifests/overlays/minikube
# Do this under the hood so CRD's get applied ahead of time and we don't see an error
kubectl apply -f ../../base/customresourcedefinition.yaml > /dev/null
pe "kubectl kustomize | kubectl apply -f -"
pe "bat --paging=never secretproviderclass.yaml"
pe "bat --paging=never pod.yaml"
pe "kubectl wait pod --all --for=condition=Ready --namespace=secrets-store-csi-driver --timeout=-1s"
pe "kubectl apply -f pod.yaml"
pe "kubectl wait --for=condition=Ready -n default pod/secrets-demo --timeout=40s"
pe 'kubectl exec -it pod/secrets-demo  -- /bin/bash -c "ls /var/run/secrets/awssecrets /var/run/secrets/azuresecrets /var/run/secrets/gcpsecrets"'
pe 'kubectl exec -it pod/secrets-demo  -- /bin/bash -c "cat /var/run/secrets/awssecrets/arn:aws:secretsmanager:us-east-1:726600616558:secret:example-aws-secret-5L2mYm; echo; cat /var/run/secrets/azuresecrets/example-azure-secret; echo; cat /var/run/secrets/gcpsecrets/example-gcp-secret"'