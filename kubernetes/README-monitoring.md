# Setting up GitHub OIDC role for deploying monitoring

This document shows how to create an AWS IAM role that GitHub Actions can assume via OIDC and how to add the role ARN to `secrets.AWS_ROLE_TO_ASSUME` in GitHub.

1) Create the role with Terraform (recommended)

- Initialize and apply the Terraform in `terraform/` (you can run from repo root):

```bash
cd terraform
terraform init
terraform apply -var='github_repo=OWNER/REPO' -var='github_branch=main' -var='aws_region=us-west-2'
```

After apply, note the `role_arn` output.

2) Alternative: create role via AWS CLI

Example assume-role-policy JSON (replace ACCOUNT_ID):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:ref:refs/heads/main"
        },
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

Create the role and attach a minimal inline policy:

```bash
aws iam create-role --role-name github-actions-eks-deploy-role --assume-role-policy-document file://assume-policy.json
cat > eks-policy.json <<'EOF'
{
  "Version":"2012-10-17",
  "Statement":[{"Effect":"Allow","Action":["eks:DescribeCluster","eks:ListClusters","sts:GetCallerIdentity"],"Resource":"*"}]
}
EOF
aws iam put-role-policy --role-name github-actions-eks-deploy-role --policy-name eks-minimal-policy --policy-document file://eks-policy.json
```

3) Map the role to Kubernetes RBAC (if you need cluster-admin for CI)

Update `aws-auth` ConfigMap in `kube-system` to map the AWS role to a Kubernetes group. Example (granting `system:masters` — use with caution):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ACCOUNT_ID:role/github-actions-eks-deploy-role
      username: github-actions
      groups:
        - system:masters
```

Apply with:

```bash
kubectl apply -f aws-auth-patch.yaml
```

4) Add role ARN to GitHub secrets

Using GitHub web UI: Settings → Secrets → Actions → New repository secret. Name: `AWS_ROLE_TO_ASSUME`, Value: role ARN.

Or with `gh` CLI:

```bash
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::ACCOUNT_ID:role/github-actions-eks-deploy-role" --repo OWNER/REPO
```

5) Test the workflow

- Trigger the `.github/workflows/deploy-monitoring.yml` via `workflow_dispatch` or push to the monitored path. Confirm `kubectl apply --dry-run` step succeeds and the role is assumed (check workflow logs).

Security notes
- Limit `StringLike` subject to the exact `repo` and branch (or use `refs/tags/*` as needed).
- Only grant needed AWS permissions; limit `Resource` when possible.
- Prefer mapping the role to a restricted Kubernetes group, not `system:masters`.
