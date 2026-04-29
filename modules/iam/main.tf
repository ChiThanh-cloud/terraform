data "aws_caller_identity" "current" {}

############################################
# IAM ROLE
############################################
resource "aws_iam_role" "this" {
  name        = "${var.name_prefix}-app-server"
  description = "EC2 backend role: SSM Session Manager + SES email sending + SSM Parameter Store read"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

############################################
# MANAGED POLICY — SSM Session Manager
# (Cho phép truy cập terminal vào EC2 qua
#  AWS Console mà không cần SSH Key Pair)
############################################
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

############################################
# INLINE POLICY — SSM Parameter Store READ
# (Cho phép EC2 đọc secrets lúc runtime,
#  ví dụ: app Node.js tự đọc db_password
#  mà không cần restart để cập nhật config)
############################################
resource "aws_iam_role_policy" "ssm_params_read" {
  name = "${var.name_prefix}-ssm-params-read"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadHospitalParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        # Chỉ cho đọc các param thuộc namespace /hospital/
        # Không cho đọc param của dự án khác
        Resource = "arn:aws:ssm:${var.ses_region}:${data.aws_caller_identity.current.account_id}:parameter/hospital/*"
      },
      {
        Sid      = "DecryptSecureString"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.ses_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

############################################
# INLINE POLICY — SES send email
############################################
resource "aws_iam_role_policy" "ses_send" {
  name = "${var.name_prefix}-ses-send"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SendEmailFromVerifiedIdentity"
        Effect = "Allow"
        Action = ["ses:SendEmail", "ses:SendRawEmail"]
        # Chỉ cho phép gửi từ đúng email đã verify trong SES
        # Resource = "*" ở đây sẽ cho phép gửi từ BẤT KỲ email nào — rất nguy hiểm
        Resource = "arn:aws:ses:${var.ses_region}:${data.aws_caller_identity.current.account_id}:identity/${var.email_from}"
      },
      {
        Sid      = "ReadSesQuota"
        Effect   = "Allow"
        Action   = ["ses:GetSendQuota", "ses:GetSendStatistics"]
        # API này không hỗ trợ resource-level, buộc phải dùng *
        Resource = "*"
      }
    ]
  })
}

############################################
# INLINE POLICY — CloudWatch Logs WRITE
# (Cho phép Docker/App đẩy log lên CloudWatch
#  để xem log tập trung mà không cần SSH vào server)
############################################
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.name_prefix}-cloudwatch-logs"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteApplicationLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.ses_region}:${data.aws_caller_identity.current.account_id}:log-group:/hospital/*"
      }
    ]
  })
}

############################################
# INSTANCE PROFILE
############################################
resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-app-server-profile"
  role = aws_iam_role.this.name
}
