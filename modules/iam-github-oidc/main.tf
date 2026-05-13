############################################
# OIDC Provider
# Registers GitHub Actions as a trusted OpenID Connect identity provider.
# This provider is account-wide and normally only needs to be created once.
############################################
data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  # GitHub Actions OIDC issuer URL.
  url = "https://token.actions.githubusercontent.com"

  # Audience expected by AWS STS when exchanging the GitHub OIDC token.
  client_id_list = ["sts.amazonaws.com"]

  # TLS certificate thumbprint used by AWS to verify the GitHub OIDC issuer.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

############################################
# IAM Role
# Role assumed by GitHub Actions during Terraform CI/CD runs.
############################################
resource "aws_iam_role" "github_actions" {
  name        = "${var.name_prefix}-github-actions"
  description = "Allow GitHub Actions repo ${var.github_repo} to run Terraform"

  # Trust policy defining which GitHub Actions workload can assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGitHubOIDC"
        Effect = "Allow"

        # Only accept tokens issued by the configured GitHub OIDC provider.
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        # Require the token to target AWS STS and originate from the expected repository and branch.
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict access to the main branch of the configured repository.
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

############################################
# Inline Policy
# Permissions granted to GitHub Actions for Terraform plan/apply operations.
############################################
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "${var.name_prefix}-terraform-execution"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        # Manage Terraform state objects in the project state bucket.
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.tf_state_bucket}",
          "arn:aws:s3:::${var.tf_state_bucket}/*"
        ]
      },
      {
        Sid    = "TerraformLockAccess"
        Effect = "Allow"
        # Manage Terraform state lock records during CI/CD runs.
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.tf_lock_table}"
      },
      {
        Sid    = "TerraformSSMReadSecrets"
        Effect = "Allow"
        # Read SSM parameters required by Terraform during plan/apply.
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/hospital/*",
          "arn:aws:ssm:${var.aws_region}::parameter/aws/service/ami-amazon-linux-latest/*"
        ]
      },
      {
        Sid      = "TerraformInfraAccess"
        Effect   = "Allow"
        # Manage the infrastructure services defined by this Terraform project.
        Action = [
          "ec2:*",
          "rds:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudfront:*",
          "wafv2:*",
          "acm:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformIamAccess"
        Effect = "Allow"
        # Limit IAM permissions to the operations Terraform needs for this project.
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreateOpenIDConnectProvider",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteOpenIDConnectProvider",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetOpenIDConnectProvider",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:TagOpenIDConnectProvider",
          "iam:TagRole",
          "iam:UntagInstanceProfile",
          "iam:UntagOpenIDConnectProvider",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.name_prefix}-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        ]
      }
    ]
  })
}
