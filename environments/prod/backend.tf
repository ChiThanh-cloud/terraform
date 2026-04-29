############################################
# REMOTE STATE BACKEND (S3 + DynamoDB lock)
# Tạo bucket trước khi chạy terraform init:
#   aws s3 mb s3://hospital-booking-tfstate --region us-east-1
#   aws dynamodb create-table \
#     --table-name hospital-booking-tflock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST
############################################
terraform {
  backend "s3" {
    bucket         = "hospital-booking-tfstate"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "hospital-booking-tflock"
  }
}
