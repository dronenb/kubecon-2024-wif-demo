#!/usr/bin/env bash
kubectl run -n default -it toolbox --image gcr.io/google.com/cloudsdktool/google-cloud-cli:489.0.0-stable --overrides='{ "spec": { "serviceAccount": "default" }  }' 

PROJECT_NUMBER=576089806637
PROJECT_ID=dronenb-kubecon-2024-demo
POOL_ID="${PROJECT_ID}"
PROVIDER_ID="${POOL_ID}"

gcloud iam workload-identity-pools create-cred-config \
    "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}" \
    --credential-source-file=/var/run/secrets/kubernetes.io/serviceaccount/token \
    --credential-source-type=text \
    --output-file=/tmp/credential-configuration.json

