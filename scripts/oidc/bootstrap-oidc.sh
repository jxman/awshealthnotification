#!/bin/bash
#
# Bootstrap GitHub Actions OIDC access for this repository.
#
# Creates (or updates) the IAM role that the Terraform workflow assumes, with the
# project-scoped policy in github-actions-policy.json. Run once locally with admin
# credentials; re-run after editing the policy file so the live policy stays in sync.
#
# Idempotent: existing resources are kept, their tags refreshed, and the policy gets a
# new default version only when the file differs from the live document.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="${SCRIPT_DIR}/github-actions-policy.json"

OIDC_URL="https://token.actions.githubusercontent.com"
ROLE_NAME="GithubActionsOIDC-AwsHealthNotification-Role"
POLICY_NAME="GithubActions-AwsHealthNotification-Policy"
GITHUB_REPO="jxman/awshealthnotification"
PROJECT_NAME="aws-health-notifications"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $*"; }
info() { echo -e "${YELLOW}⚠${NC}  $*"; }

# Standard 10 tags (role and policy differ only in Name/SubService). Fills the TAGS array,
# so values with spaces (Owner) stay one argument
tags_for() {
    TAGS=(
        "Key=Environment,Value=prod"
        "Key=ManagedBy,Value=bootstrap-script"
        "Key=Owner,Value=John Xanthopoulos"
        "Key=Project,Value=${PROJECT_NAME}"
        "Key=Service,Value=${PROJECT_NAME}"
        "Key=GithubRepo,Value=github.com/${GITHUB_REPO}"
        "Key=Site,Value=${PROJECT_NAME}"
        "Key=BaseProject,Value=${PROJECT_NAME}"
        "Key=Name,Value=$1"
        "Key=SubService,Value=$2"
    )
}

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${BLUE}GitHub Actions OIDC bootstrap: ${GITHUB_REPO} (account ${AWS_ACCOUNT_ID})${NC}"

# Step 1: OIDC provider (shared by every repo in the account; created only if missing)
OIDC_ARN=$(aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
    --output text)
if [ -z "$OIDC_ARN" ]; then
    info "OIDC provider not found, creating it"
    OIDC_ARN=$(aws iam create-open-id-connect-provider \
        --url "$OIDC_URL" \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd \
        --query OpenIDConnectProviderArn --output text)
fi
ok "OIDC provider: ${OIDC_ARN}"

# Step 2: policy, kept in sync with github-actions-policy.json
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
tags_for "$POLICY_NAME" github-actions-policy
if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --description "Terraform deploys of ${PROJECT_NAME} from GitHub Actions (project resources only)" \
        --policy-document "file://${POLICY_FILE}" \
        --tags "${TAGS[@]}" >/dev/null
    ok "Created policy: ${POLICY_ARN}"
else
    version=$(aws iam get-policy --policy-arn "$POLICY_ARN" --query Policy.DefaultVersionId --output text)
    live=$(aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$version" \
        --query PolicyVersion.Document --output json | jq -S .)
    if [ "$live" = "$(jq -S . "$POLICY_FILE")" ]; then
        ok "Policy matches ${POLICY_FILE##*/}"
    else
        # IAM keeps at most 5 versions; drop the oldest non-default one first
        oldest=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" \
            --query 'Versions[?!IsDefaultVersion].VersionId' --output text | awk '{print $NF}')
        versions=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'length(Versions)')
        if [ "$versions" -ge 5 ] && [ -n "$oldest" ]; then
            aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$oldest"
        fi
        aws iam create-policy-version --policy-arn "$POLICY_ARN" \
            --policy-document "file://${POLICY_FILE}" --set-as-default >/dev/null
        ok "Updated policy to match ${POLICY_FILE##*/}"
    fi
    aws iam tag-policy --policy-arn "$POLICY_ARN" --tags "${TAGS[@]}"
fi

# Step 3: role, trusted only by this repository (any branch, PR or environment)
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "${OIDC_ARN}" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": { "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*" }
    }
  }]
}
EOF
)
tags_for "$ROLE_NAME" github-actions-role
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --description "GitHub Actions OIDC role for ${GITHUB_REPO} Terraform deploys" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --tags "${TAGS[@]}" >/dev/null
    ok "Created role: ${ROLE_NAME}"
else
    aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "$TRUST_POLICY"
    aws iam tag-role --role-name "$ROLE_NAME" --tags "${TAGS[@]}"
    ok "Role exists, trust policy and tags refreshed: ${ROLE_NAME}"
fi
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
ok "Policy attached"

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text)
echo ""
echo "Role ARN: ${ROLE_ARN}"
echo "It must match AWS_ROLE_ARN in .github/workflows/terraform.yml"
