#!/bin/bash

set -euo pipefail

printf "Getting GitHub Token"

export GH_APP_ID=$(vault kv get -field="gh_app_id" kv/k8s/gitlab-runner/datadog-aas-extension/secret)
export GH_PRIVATE_KEY=$(vault kv get -field="gh_private_key" kv/k8s/gitlab-runner/datadog-aas-extension/secret)
export GH_INSTALLATION_ID=$(vault kv get -field="gh_installation_id" kv/k8s/gitlab-runner/datadog-aas-extension/secret)

# Write private key to a temporary file
PRIVATE_KEY_FILE=$(mktemp)
echo "$GH_PRIVATE_KEY" > "$PRIVATE_KEY_FILE"

export JWT_TOKEN=$(bash .gitlab/scripts/generate_jwt.sh $GH_APP_ID $PRIVATE_KEY_FILE)

export GH_TOKEN=$(curl -s -X POST \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/app/installations/$GH_INSTALLATION_ID/access_tokens" | jq -r '.token')

gh auth status
