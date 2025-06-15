#!/bin/bash

# Get variables from the main script via arguments
USER_EMAIL=$1
DOMAIN_NAME=$2
GENERIC_TIMEZONE=$3

if [ -z "$USER_EMAIL" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "ERROR: Email or domain name not specified"
  echo "Usage: $0 user@example.com example.com [timezone]"
  exit 1
fi

if [ -z "$GENERIC_TIMEZONE" ]; then
  GENERIC_TIMEZONE="UTC"
fi

echo "Generating secret keys and passwords..."

# Function to generate random strings
generate_random_string() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()-_=+' | fold -w ${length} | head -n 1
}

# Function to generate safe passwords (no special bash characters)
generate_safe_password() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${length} | head -n 1
}

# Function to generate passwords with special characters for Flowise
generate_flowise_password() {
  length=$1
  # Генерируем основную часть пароля (length-1 символов)
  base_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $((length-1)) | head -n 1)
  # Получаем случайный спецсимвол
  special_char=$(cat /dev/urandom | tr -dc '!@#$%^&*()-_=+' | fold -w 1 | head -n 1)
  # Случайная позиция для вставки спецсимвола
  position=$((RANDOM % ${#base_password}))
  # Вставляем спецсимвол в случайную позицию
  echo ${base_password:0:$position}${special_char}${base_password:$position}
}

# Generating keys and passwords
N8N_ENCRYPTION_KEY=$(generate_random_string 40)
if [ -z "$N8N_ENCRYPTION_KEY" ]; then
  echo "ERROR: Failed to generate encryption key for n8n"
  exit 1
fi

N8N_USER_MANAGEMENT_JWT_SECRET=$(generate_random_string 40)
if [ -z "$N8N_USER_MANAGEMENT_JWT_SECRET" ]; then
  echo "ERROR: Failed to generate JWT secret for n8n"
  exit 1
fi

# Use safer password generation function (alphanumeric only)
N8N_PASSWORD=$(generate_safe_password 16)
if [ -z "$N8N_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for n8n"
  exit 1
fi

# Используем специальную функцию для генерации пароля с обязательным спецсимволом
FLOWISE_PASSWORD=$(generate_flowise_password 16)
if [ -z "$FLOWISE_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Flowise"
  exit 1
fi

# Генерация дополнительных секретов для новой системы аутентификации Flowise v3.0.1+
JWT_AUTH_TOKEN_SECRET=$(generate_random_string 40)
if [ -z "$JWT_AUTH_TOKEN_SECRET" ]; then
  echo "ERROR: Failed to generate JWT auth token secret for Flowise"
  exit 1
fi

JWT_REFRESH_TOKEN_SECRET=$(generate_random_string 40)
if [ -z "$JWT_REFRESH_TOKEN_SECRET" ]; then
  echo "ERROR: Failed to generate JWT refresh token secret for Flowise"
  exit 1
fi

EXPRESS_SESSION_SECRET=$(generate_random_string 30)
if [ -z "$EXPRESS_SESSION_SECRET" ]; then
  echo "ERROR: Failed to generate Express session secret for Flowise"
  exit 1
fi

TOKEN_HASH_SECRET=$(generate_random_string 40)
if [ -z "$TOKEN_HASH_SECRET" ]; then
  echo "ERROR: Failed to generate token hash secret for Flowise"
  exit 1
fi

# Генерация учетных данных и секретов для Redis
REDIS_PASSWORD=$(generate_random_string 20)
if [ -z "$REDIS_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Redis"
  exit 1
fi

# Генерация учетных данных для PostgreSQL
POSTGRES_USER="flowise"
POSTGRES_PASSWORD=$(generate_random_string 20)
POSTGRES_DB="flowise"
if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for PostgreSQL"
  exit 1
fi

# Writing values to .env file
cat > .env << EOL
# Settings for n8n
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET
N8N_DEFAULT_USER_EMAIL=$USER_EMAIL
N8N_DEFAULT_USER_PASSWORD=$N8N_PASSWORD

# n8n host configuration
SUBDOMAIN=n8n
GENERIC_TIMEZONE=$GENERIC_TIMEZONE

# Settings for Flowise (старая система аутентификации)
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=$FLOWISE_PASSWORD

# Settings for Flowise v3.0.1+ (новая система аутентификации)
JWT_AUTH_TOKEN_SECRET=$JWT_AUTH_TOKEN_SECRET
JWT_REFRESH_TOKEN_SECRET=$JWT_REFRESH_TOKEN_SECRET
EXPRESS_SESSION_SECRET=$EXPRESS_SESSION_SECRET
TOKEN_HASH_SECRET=$TOKEN_HASH_SECRET

# Redis configuration
REDIS_PASSWORD=$REDIS_PASSWORD

# PostgreSQL configuration
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB

# Domain settings
DOMAIN_NAME=$DOMAIN_NAME
EOL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create .env file"
  exit 1
fi

echo "Secret keys generated and saved to .env file"
echo "Password for n8n: $N8N_PASSWORD"
echo "Password for Flowise: $FLOWISE_PASSWORD"

# Save passwords for future use - using quotes to properly handle special characters
echo "N8N_PASSWORD=\"$N8N_PASSWORD\"" > ./setup-files/passwords.txt
echo "FLOWISE_PASSWORD=\"$FLOWISE_PASSWORD\"" >> ./setup-files/passwords.txt

echo "✅ Secret keys and passwords successfully generated"
exit 0 