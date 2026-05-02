############################################
# OIDC PROVIDER — Khai báo với AWS rằng
# "Tôi tin tưởng GitHub làm Identity Provider"
# Chỉ tạo 1 lần duy nhất cho toàn bộ tài khoản AWS.
############################################
resource "aws_iam_openid_connect_provider" "github" {
  # Địa chỉ của GitHub OIDC Server — không bao giờ thay đổi
  url = "https://token.actions.githubusercontent.com"

  # AWS cần biết Token này được tạo ra "cho ai dùng"
  # "sts.amazonaws.com" là dịch vụ AWS dùng để đổi Token tạm thời
  client_id_list = ["sts.amazonaws.com"]

  # "Vân tay" (thumbprint) của chứng chỉ TLS của GitHub
  # AWS dùng cái này để xác nhận Token đến thật sự từ GitHub,
  # không phải từ kẻ giả mạo
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

############################################
# IAM ROLE — Vai trò mà GitHub Actions
# sẽ "mặc vào" trong lúc chạy pipeline
############################################
resource "aws_iam_role" "github_actions" {
  name        = "${var.name_prefix}-github-actions"
  description = "Allow GitHub Actions repo ${var.github_repo} to run Terraform"

  # TRUST POLICY — Quy tắc "Ai được phép mặc Role này?"
  # Đây là trái tim của toàn bộ cơ chế OIDC
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGitHubOIDC"
        Effect = "Allow"

        # Chỉ cho phép Token đến từ GitHub OIDC Provider
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        # Điều kiện bảo mật — Quan trọng nhất!
        # Ngay cả khi Token đến từ GitHub, nó cũng phải thỏa mãn
        # 2 điều kiện này mới được cấp quyền
        Condition = {
          StringEquals = {
            # Điều kiện 1: Token phải được tạo ra cho đúng dịch vụ STS
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Điều kiện 2: Token phải đến từ đúng Repo của bạn
            # "sub" (subject) chứa thông tin repo và branch
            # ref:refs/heads/main → Chỉ cho phép nhánh "main"
            # Dùng wildcard (*) nếu muốn cho phép mọi nhánh
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

############################################
# INLINE POLICY — Quyền hạn của Role
# Đây là danh sách những gì GitHub Actions
# được phép làm trên AWS của bạn
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
        # Cho phép đọc/ghi file tfstate trong đúng cái Bucket của dự án
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
        # Cho phép khóa/mở khóa State khi đang chạy
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
        # Cho phép đọc Secrets để plan/apply (giống EC2 đọc SSM)
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
        # Cho phép quản lý toàn bộ hạ tầng của dự án
        # Ghi chú: Trong môi trường Enterprise thực tế,
        # bạn nên chia nhỏ thành các policy riêng biệt
        # để tuân thủ nguyên tắc Least Privilege chặt chẽ hơn
        Action = [
          "ec2:*",
          "rds:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudfront:*",
          "wafv2:*",
          "iam:*",
          "acm:*",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })
}
