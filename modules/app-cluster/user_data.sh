#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data 2>/dev/console) 2>&1

APP_DIR="/opt/webhospital-booking"

echo "=== [1/5] Install OS packages & Docker ==="
dnf update -y
dnf install -y git mariadb105 docker awscli-2
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "=== [2/5] Clone repository ==="
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
git clone --depth 1 "${github_repo_url}" "$APP_DIR"

echo "=== [3/5] Fetch runtime secrets from SSM and write backend/.env ==="
DB_USERNAME=$(aws ssm get-parameter \
  --name "${db_username}" \
  --query "Parameter.Value" \
  --output text)

DB_PASSWORD=$(aws ssm get-parameter \
  --name "${db_password}" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

cat > "$APP_DIR/backend/.env" <<EOF_ENV
NODE_ENV=production
PORT=5000
DB_MODE=mysql
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=$${DB_USERNAME}
DB_PASSWORD=$${DB_PASSWORD}
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
BCRYPT_SALT_ROUNDS=10
CORS_ORIGIN=${cors_origin}
EMAIL_PROVIDER=${email_provider}
AWS_REGION=${aws_region}
AWS_SES_REGION=${ses_region}
EMAIL_FROM=${email_from}
PATIENT_RESET_OTP_LENGTH=6
PATIENT_RESET_OTP_TTL_SECONDS=300
PATIENT_RESET_OTP_RESEND_SECONDS=60
PATIENT_RESET_OTP_PREVIEW=true
EOF_ENV
chmod 600 "$APP_DIR/backend/.env"

echo "=== [4/5] Wait for RDS & seed schema ==="
for i in $(seq 1 60); do
  if MYSQL_PWD="$${DB_PASSWORD}" mysql --protocol=tcp --connect-timeout=5 -h '${db_host}' -P '${db_port}' -u "$${DB_USERNAME}" -D '${db_name}' -e "SELECT 1;" >/dev/null 2>&1; then
    echo "RDS ready — seeding schema..."
    MYSQL_PWD="$${DB_PASSWORD}" mysql --default-character-set=utf8mb4 --protocol=tcp \
      -h '${db_host}' -P '${db_port}' -u "$${DB_USERNAME}" -D '${db_name}' \
      < "$APP_DIR/database/schema.sql" || echo "Note: schema already exists or no schema.sql"
    break
  fi
  echo "Waiting for RDS... attempt $i/60"
  sleep 10
done

echo "=== [5/5] Build & Run Docker (Production) ==="
cd "$APP_DIR"
# docker-compose.prod.yml nằm trong repo, không có MySQL, dùng AWS RDS
docker-compose -f docker-compose.prod.yml up --build -d

echo "=== Done ==="
