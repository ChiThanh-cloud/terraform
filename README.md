# 🏥 Hospital Booking System – AWS Infrastructure (Terraform)

<p align="center">
  <img src="https://img.shields.io/badge/Terraform-≥1.5.0-7B42BC?logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

> Production-oriented AWS infrastructure for the [Hospital Booking System](https://github.com/ChiThanh-cloud/webhospital-booking), provisioned entirely with **Terraform** (Infrastructure as Code).  
> Frontend & Backend run as **Docker containers** on EC2 — portable, reproducible, and zero manual server setup.

---

## ✨ Architecture Overview

```
                          ┌─────────────────────────────────┐
                          │            Internet             │
                          └───────────────┬─────────────────┘
                                          │
                          ┌───────────────▼─────────────────┐
                          │         CloudFront CDN           │
                          │ HTTPS · Domain · Optional WAF    │
                          │  ACM SSL      │
                          └───────────────┬─────────────────┘
                                          │
                          ┌───────────────▼─────────────────┐
                          │   Application Load Balancer      │
                          │   Health Check: GET /health      │
                          └───────────────┬─────────────────┘
                                          │
                          ┌───────────────▼─────────────────┐
                          │     EC2 Auto Scaling Group       │
                          │  ┌───────────────────────────┐  │
                          │  │   Docker Compose           │  │
                          │  │   ├── Frontend (React/Nginx)│  │
                          │  │   └── Backend  (Node.js)   │  │
                          │  └───────────────────────────┘  │
                          │  IAM Role: SSM + SES (no keys)  │
                          └───────────────┬─────────────────┘
                                          │ Port 3306 only
                          ┌───────────────▼─────────────────┐
                          │       RDS MySQL 8.0              │
                          │  Private · Security Group locked │
                          └─────────────────────────────────┘
```

---

## 🗂️ Project Structure

```
terraform/
│
├── environments/
│   └── prod/
│       ├── backend.tf          # S3 remote state backend
│       ├── providers.tf        # Terraform and AWS provider configuration
│       ├── variables.tf        # Production input variables
│       ├── terraform.tfvars    # Non-sensitive production values
│       ├── main.tf             # Composition layer wiring all modules
│       └── outputs.tf          # Deployment outputs
│
├── modules/
│   ├── network/                # Default VPC lookup and security groups
│   ├── iam/                    # EC2 instance profile and runtime permissions
│   ├── database/               # RDS MySQL and DB subnet group
│   ├── app-cluster/            # ALB, Launch Template, Auto Scaling Group
│   ├── cdn-waf/                # CloudFront distribution and optional WAF
│   └── iam-github-oidc/        # GitHub Actions OIDC role for Terraform CI/CD
│
├── .github/workflows/
│   └── terraform.yml           # Terraform CI/CD pipeline
│
├── README.md                   # Project overview and usage
└── INFRASTRUCTURE.md           # Research/defense architecture notes
```

---

## 🔧 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| IaC | **Terraform ≥ 1.5** | Provision & manage all AWS resources |
| CDN | **AWS CloudFront** | Global edge caching, HTTPS termination |
| SSL | **AWS ACM** | Free auto-renewing SSL certificate |
| Load Balancer | **AWS ALB** | Traffic distribution, health checks |
| Compute | **EC2 + Auto Scaling** | Self-healing, scalable app servers |
| Containers | **Docker Compose** | Run Frontend + Backend as containers |
| Database | **RDS MySQL 8.0** | Managed relational database |
| Secrets | **SSM Parameter Store** | Zero-hardcode secret management |
| IAM | **EC2 IAM Role** | Keyless AWS access (Least Privilege) |
| Email | **AWS SES** | Transactional email via IAM Role |
| Security | **Optional AWS WAF v2** | Rate limiting, IP reputation, OWASP managed rules |

--- 

## 🔒 Security Highlights

### ✅ No Access Keys on EC2
EC2 uses an **IAM Instance Profile** — never an `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY`. The role grants only what the app needs:
- `AmazonSSMManagedInstanceCore` — keyless SSH via AWS Systems Manager.
- `ses:SendEmail` — scoped to a single verified SES identity.

### ✅ Secrets Never in Code
All sensitive values are stored in **AWS SSM Parameter Store**. Terraform uses the database password only where it is required to provision RDS, while EC2 receives SSM parameter names and fetches runtime secrets with its instance role during bootstrap. This keeps database credentials out of the Launch Template `user_data` and reduces secret exposure in bootstrap logs.

### ✅ Scoped IAM for CI/CD
GitHub Actions uses OIDC instead of long-lived AWS keys. The Terraform CI/CD role keeps broad infrastructure permissions for the services managed by this research project, but IAM permissions are explicitly listed instead of using `iam:*`. This makes the most sensitive permission group easier to audit and explain.

### ✅ Defense in Depth (Network Layers)
```
Internet  →  ALB SG (port 80 only)
          →  EC2 SG (accepts traffic from ALB SG only)
          →  RDS SG (accepts port 3306 from EC2 SG only)
```

---

## ⚙️ Configuration

### Variables (non-sensitive) — `terraform.tfvars`

```hcl
aws_region = "us-east-1"
app_port   = 80
```

### Secrets — AWS SSM Parameter Store

Create these **once** before running `terraform apply`:

```bash
# Database credentials
aws ssm put-parameter --name "/hospital/prod/db_username" \
  --value "admin" --type String --overwrite

aws ssm put-parameter --name "/hospital/prod/db_password" \
  --value "YOUR_DB_PASSWORD" --type SecureString --overwrite

# EC2 Key Pair
aws ssm put-parameter --name "/hospital/prod/key_name" \
  --value "your-keypair-name" --type String --overwrite

# Application
aws ssm put-parameter --name "/hospital/prod/github_repo_url" \
  --value "https://github.com/ChiThanh-cloud/webhospital-booking.git" \
  --type String --overwrite

aws ssm put-parameter --name "/hospital/prod/email_from" \
  --value "your-verified-ses-email@gmail.com" --type String --overwrite
```

### All Available Variables

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS deployment region |
| `project_name` | `hospital-booking` | Resource name prefix |
| `environment` | `prod` | Environment tag (dev/staging/prod) |
| `ec2_instance_type` | `t3.micro` | EC2 instance size |
| `db_instance_class` | `db.t3.micro` | RDS instance size |
| `app_port` | `80` | Port exposed by Nginx to ALB |
| `email_provider` | `ses` | `ses` or `ethereal` (test mode) |
| `ses_region` | `us-east-1` | AWS SES region |
| `enable_waf` | `false` | Toggle optional WAF on/off |
| `waf_rate_limit` | `1000` | Requests per 5 min per IP |

---

## 🚀 Quick Start

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) ≥ 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate permissions
- An existing EC2 Key Pair in your AWS account
- A verified SES email identity

### Deploy

```bash
# 1. Clone this repository
git clone https://github.com/ChiThanh-cloud/terraform.git
cd terraform

# 2. Create SSM secrets (see Configuration section above)

# 3. Initialize Terraform
terraform init

# 4. Preview infrastructure changes
terraform plan

# 5. Apply (≈ 10–15 minutes for full stack)
terraform apply
```

### Post-Deploy DNS Setup

After `terraform apply` completes, point your custom domain to CloudFront:

1. Copy the `cloudfront_domain` output value (e.g. `d1234abcdef.cloudfront.net`).
2. In your DNS provider, create a **CNAME record**:
   ```
   nguyenchithanhit.id.vn  →  d1234abcdef.cloudfront.net
   ```
3. Wait 5–10 minutes for DNS propagation. Your app will be live at:  
   **`https://nguyenchithanhit.id.vn`** 🎉

### Destroy

```bash
terraform destroy
```

---

## 📤 Outputs

| Output | Description |
|---|---|
| `app_url` | `https://nguyenchithanhit.id.vn` — Production URL |
| `alb_url` | Direct ALB URL (for debugging) |
| `cloudfront_domain` | Default CloudFront domain |
| `cloudfront_distribution_id` | Use to invalidate CDN cache after deploys |
| `rds_endpoint` | MySQL endpoint (sensitive, internal VPC only) |

---

## 📁 Related Repositories

| Repository | Description |
|---|---|
| [webhospital-booking](https://github.com/ChiThanh-cloud/webhospital-booking) | Main application (React Frontend + Node.js Backend) |
| [terraform](https://github.com/ChiThanh-cloud/terraform) | This repository — AWS Infrastructure as Code |

---

## 👤 Author

**Nguyễn Chí Thành**  
[![GitHub](https://img.shields.io/badge/GitHub-ChiThanh--cloud-181717?logo=github)](https://github.com/ChiThanh-cloud)

---

<p align="center">Made with ❤️ using Terraform & AWS</p>
