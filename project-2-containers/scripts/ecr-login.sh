#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-ap-southeast-2}"
REPO="${2:-devops-project-2-app}"
ACCOUNT_ID="483647879983"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO"

echo "Using registry: $ECR_URL"

aws ecr describe-repositories \
  --region "$REGION" \
  --repository-names "$REPO" \
  >/dev/null 2>&1 || {
  echo "Creating repository $REPO in $REGION"
  aws ecr create-repository --region "$REGION" --repository-name "$REPO"
}

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ECR_URL"

echo "Logged into $ECR_URL"
