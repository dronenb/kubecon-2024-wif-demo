#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s failglob

mkdir -p manifests/base
pushd manifests/base > /dev/null || exit 1

# helm search repo secrets-store-csi-driver/secrets-store-csi-driver --versions
export VERSION="1.4.6"
export NAMESPACE=secrets-store-csi-driver

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update
helm template csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
    --include-crds \
    --version "${VERSION}" \
    --namespace "${NAMESPACE}" \
    --set syncSecret.enabled=true \
    --set enableSecretRotation=true \
    --set linux.crds.enabled=false | \
    yq --no-colors --prettyPrint '... comments=""' | \
    kubectl-slice -o . --template "{{ .kind | lower }}.yaml"

echo "---" > namespace.yaml
kubectl create namespace "${NAMESPACE}" -o yaml --dry-run=client | \
    kubectl neat \
    >> namespace.yaml

kustomize create --autodetect --namespace "${NAMESPACE}"

# Format YAML
prettier . --write
popd > /dev/null || exit 1

mkdir -p manifests/components/aws-provider
pushd manifests/components/aws-provider > /dev/null || exit 1

curl -sL https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml | \
    yq --no-colors --prettyPrint '... comments=""' | \
    kubectl-slice -o . --template "{{ .kind | lower }}.yaml"

# Probably isn't necessary for minikube... was necessary on k3s on CoreOS w/ SELinux enabled though.
yq -i e '.spec.template.spec.containers[].securityContext += {"privileged" : true,"allowPrivilegeEscalation":true}' daemonset.yaml

kustomize create --autodetect --namespace "${NAMESPACE}"
prettier . --write
popd > /dev/null || exit 1


mkdir -p manifests/components/gcp-provider
pushd manifests/components/gcp-provider > /dev/null || exit 1

COMMIT_SHA=7218875135b87ca930b9bcb97231b1ede4e93e1a # v1.6.0

curl -sL "https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/${COMMIT_SHA}/deploy/provider-gcp-plugin.yaml" |
    yq --no-colors --prettyPrint '... comments=""' | \
    kubectl-slice -o . --template "{{ .kind | lower }}.yaml"

# Iterate over each yaml file
files=()
for file in *.yaml; do
    if [[ "${file}" == "kustomization.yaml" ]]; then
        continue
    fi
    files+=("${file}")
    contents="$(cat "${file}")"
    printf -- "---\n# yamllint disable rule:line-length\n%s" "${contents}" > "${file}"
done

# because of SELinux, need to write custom policy... a TODO
# This probably isn't necessary in minikube
yq -i e '.spec.template.spec.initContainers[].securityContext += {"privileged" : true, "allowPrivilegeEscalation":true}' daemonset.yaml
yq -i e '.spec.template.spec.containers[].securityContext += {"privileged" : true,"allowPrivilegeEscalation":true}' daemonset.yaml
yq -i e '.subjects[].namespace = "'"${NAMESPACE}"'"' clusterrolebinding.yaml

PROJECT_NUMBER=576089806637
POOL_ID=dronenb-kubecon-2024-demo
PROVIDER_ID=kubecon-2024-demo

mkdir config
# https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes#deploy
gcloud iam workload-identity-pools create-cred-config \
    "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}" \
    --credential-source-file=/var/run/secrets/kubernetes.io/serviceaccount/token \
    --credential-source-type=text \
    --output-file=./config/credential-configuration.json

# https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/blob/main/docs/fleet-wif-notes.md
yq -i e '.spec.template.spec.volumes += [{"name":"gcp-ksa","projected":{"defaultMode":420,"sources":[{"serviceAccountToken":{"audience":"k3s","expirationSeconds":3600,"path":"token"}},{"configMap":{"items":[{"key":"credential-configuration.json","path":"credential-configuration.json"}],"name":"default-creds-config","optional":false}}]}}]' daemonset.yaml
yq -i e '.spec.template.spec.containers[0].volumeMounts += [{"mountPath":"/var/run/secrets/tokens/gcp-ksa","name":"gcp-ksa","readOnly":true}]' daemonset.yaml
yq -i e '.spec.template.spec.containers[0].env += [{"name":"GOOGLE_APPLICATION_CREDENTIALS","value":"/var/run/secrets/tokens/gcp-ksa/credential-configuration.json"}]' daemonset.yaml
# I am using a custom image for GCP secrets store CSI provider so I can use per namespace WIF
# It's a new feature, not in a release yet: https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/pull/459
yq -i e '.spec.template.spec.containers[0].image = "docker.io/dronenb/secrets-store-csi-driver-provider-gcp@sha256:f3d0b978ce19d712514cafba17ba81fbb323379af42c1ebbe10e260d2485fcd6"' daemonset.yaml
# https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/blob/main/docs/fleet-wif-notes.md#set-gaia_token_exchange_endpoint-and-appropriate-audience
yq -i e '.spec.template.spec.containers[0].env += [{"name":"GAIA_TOKEN_EXCHANGE_ENDPOINT","value":"https://sts.googleapis.com/v1/token"}]' daemonset.yaml
yq -i e '.spec.template.spec.containers[0].args += ["-v=5"]' daemonset.yaml
# Create kustomize file
cat <<EOF > kustomization.yaml
---
kind: Kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
namespace: ${NAMESPACE}
resources:
$(printf "  - %s\n" "${files[@]}")
configMapGenerator:
- name: default-creds-config
  files:
    - config/credential-configuration.json
EOF

# Format YAML
prettier . --write
popd > /dev/null || exit 1

mkdir -p manifests/components/azure-provider
pushd manifests/components/azure-provider > /dev/null || exit 1

export VERSION="1.5.6"
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm repo update
helm template csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
    --include-crds \
    --version "${VERSION}" \
    --namespace "${NAMESPACE}" \
    --set secrets-store-csi-driver.syncSecret.enabled=true \
    --set linux.providersDir=/etc/kubernetes/secrets-store-csi-providers \
    --set secrets-store-csi-driver.install=false | \
    yq --no-colors --prettyPrint '... comments=""' | \
    kubectl-slice -o . --template "{{ .kind | lower }}.yaml"

yq -i e '.spec.template.spec.containers[].securityContext += {"privileged" : true,"allowPrivilegeEscalation":true}' daemonset.yaml

kustomize create --autodetect --namespace "${NAMESPACE}"
