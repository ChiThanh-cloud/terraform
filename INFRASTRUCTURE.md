# Infrastructure Notes for Research Defense

## 1. Research Goal

This repository demonstrates how Terraform can automate a production-oriented AWS deployment for a hospital booking web application. The main research focus is Infrastructure as Code, repeatable cloud provisioning, CI/CD integration, and secure handling of runtime configuration without committing secrets to Git.

## 2. Architecture Overview

The system is deployed in the `prod` environment and composed from reusable Terraform modules:

- `network`: discovers the default VPC and creates security groups for ALB, EC2, and RDS.
- `iam`: creates the EC2 IAM role, instance profile, SSM Session Manager access, SES permissions, SSM read access, and CloudWatch Logs write access.
- `database`: provisions private RDS MySQL 8.0.
- `app-cluster`: provisions an internet-facing ALB, target group, launch template, and Auto Scaling Group.
- `cdn-waf`: provisions CloudFront and, when enabled, attaches AWS WAF v2 to the ALB.
- `iam-github-oidc`: allows GitHub Actions to assume an AWS IAM role through OIDC instead of long-lived access keys.

Traffic flow:

```text
User -> CloudFront -> Application Load Balancer -> EC2 Auto Scaling Group -> RDS MySQL
```

Security group flow:

```text
Internet -> ALB security group on port 80
ALB security group -> EC2 security group on the application port
EC2 security group -> RDS security group on port 3306
```

## 3. CI/CD and Remote State

Terraform state is stored remotely in S3 through `environments/prod/backend.tf`. The backend uses server-side encryption and S3 native lockfile support to reduce concurrent state modification risk.

GitHub Actions runs Terraform from `.github/workflows/terraform.yml`:

- Pull requests run `terraform init`, `fmt`, `validate`, and `plan`.
- Pushes to `main` run the same checks and then `terraform apply`.
- AWS authentication uses GitHub OIDC and `AWS_ROLE_ARN`, so no AWS access key is stored in GitHub Secrets.

The provider lock file `environments/prod/.terraform.lock.hcl` should be committed to keep Terraform provider resolution reproducible across machines and CI runners.

## 4. Secret Management

Application and database secrets are stored in AWS SSM Parameter Store under `/hospital/prod/...`. Terraform still reads the database username and password where required to create the RDS instance, but the EC2 Launch Template no longer receives plaintext database credentials in `user_data`.

For application bootstrap, Terraform passes SSM parameter names to EC2. The instance uses its IAM instance profile to call `aws ssm get-parameter` and writes the resolved values to `backend/.env` locally on the instance.

Why this design was chosen:

- It prevents database credentials from being embedded directly into Launch Template user data.
- It reduces the chance of credentials appearing in EC2 bootstrap command traces.
- It uses the existing EC2 IAM role and SSM Parameter Store instead of long-lived static credentials.
- It keeps the application deploy flow simple enough for research defense while improving the security posture.

Required parameters:

- `/hospital/prod/db_username`
- `/hospital/prod/db_password`
- `/hospital/prod/key_name`
- `/hospital/prod/github_repo_url`
- `/hospital/prod/email_from`

## 5. Strengths

- Modular Terraform layout makes the system easier to explain, reuse, and extend.
- Remote state avoids local-only infrastructure management.
- GitHub OIDC avoids long-lived AWS access keys in CI/CD.
- The GitHub Actions role avoids `iam:*` and lists the specific IAM operations Terraform needs for this project.
- Runtime database credentials are fetched by EC2 from SSM instead of being rendered into Launch Template user data.
- RDS is not publicly accessible and only accepts traffic from the EC2 security group.
- EC2 instances can be accessed through SSM Session Manager instead of direct SSH.
- CloudFront provides HTTPS termination and edge delivery for the public application.

## 6. Current Limitations

These limitations are intentional for a balanced research/demo scope and should be discussed during defense:

- The network module uses the AWS default VPC instead of creating custom public/private subnets and NAT gateways.
- The GitHub Actions Terraform role still uses broad non-IAM service permissions such as `ec2:*` and `rds:*` for faster iteration.
- RDS has `deletion_protection = false` and `skip_final_snapshot = true`, which is convenient for demo cleanup but not recommended for strict production.
- The RDS password must still be present in Terraform state because Terraform manages the RDS instance password. A stricter production design would rotate or manage this outside the main state workflow.
- EC2 still writes secrets to a local `.env` file for compatibility with the current application. A stronger production pattern would let the application read SSM or AWS Secrets Manager directly at runtime.
- WAF is implemented but disabled by default through `enable_waf = false` to control cost and simplify demos.

## 7. Future Improvements

- Replace default VPC usage with a custom VPC, private subnets, NAT gateways, and explicit route tables.
- Continue narrowing non-IAM Terraform permissions with tag conditions and resource prefixes.
- Add `tflint`, `tfsec`, or `checkov` to CI for static security and quality scanning.
- Enable RDS deletion protection and final snapshots for production deployments.
- Add CloudWatch dashboards, alarms, and log retention policies.
- Move secret retrieval from bootstrap-time injection to runtime access through the application or AWS Secrets Manager.
