#!/bin/bash
set -ex
exec > >(tee /var/log/user-data.log | logger -t user-data 2>/dev/console) 2>&1

APP_DIR="/opt/webhospital-booking"
APP_USER="ec2-user"

echo "=== [1/6] Install OS packages & Docker ==="
dnf update -y
dnf install -y git mariadb105 docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "=== [2/6] Clone repository ==="
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
git clone --depth 1 "${github_repo_url}" "$APP_DIR"

echo "=== [3/6] Setup Environment Variables ==="
cat > "$APP_DIR/backend/.env" <<EOF_ENV
NODE_ENV=production
PORT=5000
DB_MODE=mysql
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
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

echo "=== [4/6] Wait for RDS ==="
for i in $(seq 1 60); do
  if MYSQL_PWD='${db_password}' mysql --protocol=tcp --connect-timeout=5 -h '${db_host}' -P '${db_port}' -u '${db_username}' -D '${db_name}' -e "SELECT 1;" >/dev/null 2>&1; then
    echo "RDS ready"
    echo "Initializing database schema..."
    MYSQL_PWD='${db_password}' mysql --default-character-set=utf8mb4 --protocol=tcp -h '${db_host}' -P '${db_port}' -u '${db_username}' -D '${db_name}' < "$APP_DIR/database/schema.sql" || echo "Note: No schema.sql found or error during import"
    echo "Database schema initialized successfully"
    break
  fi
  echo "Waiting for RDS attempt $i/60"
  sleep 10
done

echo "=== [5/6] Setup frontend environment ==="
cat > "$APP_DIR/frontend/.env.production" <<EOF_ENV_FE
VITE_API_URL=/api
VITE_SOCKET_URL=
EOF_ENV_FE

echo "=== [6/6] Build and Run Docker ==="
cd "$APP_DIR"
docker-compose -f deploy/docker/docker-compose.yml up --build -d

echo "=== Done ==="
