#!/bin/bash

# Get variables from the main script via arguments
DOMAIN_NAME=$1

if [ -z "$DOMAIN_NAME" ]; then
  echo "ERROR: Domain name not specified"
  echo "Usage: $0 example.com"
  exit 1
fi

echo "Creating templates and configuration files..."

# Check for template files and create them
if [ ! -f "n8n-docker-compose.yaml.template" ]; then
  echo "Creating template n8n-docker-compose.yaml.template..."
  cat > n8n-docker-compose.yaml.template << EOL
version: '3'

volumes:
  n8n_data:
    external: true
  caddy_data:
    external: true
  caddy_config:
  redis_data:
    external: true
  postgres_data:
    external: true
  pgadmin_data:
    external: true

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    depends_on:
      - redis
      - postgres
    environment:
      # Основные настройки
      - N8N_ENCRYPTION_KEY=\${N8N_ENCRYPTION_KEY}
      - N8N_USER_MANAGEMENT_DISABLED=false
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_PERSONALIZATION_ENABLED=false
      - N8N_USER_MANAGEMENT_JWT_SECRET=\${N8N_USER_MANAGEMENT_JWT_SECRET}
      - N8N_DEFAULT_USER_EMAIL=\${N8N_DEFAULT_USER_EMAIL}
      - N8N_DEFAULT_USER_PASSWORD=\${N8N_DEFAULT_USER_PASSWORD}
      - N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
      # Базовая аутентификация
      - N8N_BASIC_AUTH_ACTIVE=\${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=\${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=\${N8N_BASIC_AUTH_PASSWORD}
      # Основные настройки URL
      - N8N_HOST=\${SUBDOMAIN}.\${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://\${SUBDOMAIN}.\${DOMAIN_NAME}/
      - GENERIC_TIMEZONE=\${GENERIC_TIMEZONE}
      # Настройки Redis для очереди
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_PASSWORD=\${REDIS_PASSWORD}
      # Настройки PostgreSQL для хранения данных
      - DB_TYPE=postgresdb
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=\${POSTGRES_DB}
      - DB_USER=\${POSTGRES_USER}
      - DB_PASSWORD=\${POSTGRES_PASSWORD}
      - DB_POSTGRESDB_SCHEMA=public
    volumes:
      - n8n_data:/home/node/.n8n
      - /opt/n8n/files:/files
    networks:
      - app-network

  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
    volumes:
      - /opt/n8n/Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - app-network
      
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --requirepass \${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - app-network

  postgres:
    image: ankane/pgvector:latest
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=\${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  pgadmin:
    image: dpage/pgadmin4:8.3
    container_name: pgadmin
    restart: unless-stopped
    depends_on:
      - postgres
    environment:
      - PGADMIN_DEFAULT_EMAIL=\${PGADMIN_DEFAULT_EMAIL}
      - PGADMIN_DEFAULT_PASSWORD=\${PGADMIN_DEFAULT_PASSWORD}
      - PGADMIN_CONFIG_SERVER_MODE=True
      - PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    networks:
      - app-network

networks:
  app-network:
    name: app-network
    driver: bridge
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file n8n-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template n8n-docker-compose.yaml.template already exists"
fi

if [ ! -f "flowise-docker-compose.yaml.template" ]; then
  echo "Creating template flowise-docker-compose.yaml.template..."
  cat > flowise-docker-compose.yaml.template << EOL
version: '3'

volumes:
  redis_data:
    external: true
  postgres_data:
    external: true

services:
  flowise:
    image: flowiseai/flowise
    restart: unless-stopped
    container_name: flowise
    depends_on:
      - redis
      - postgres
    environment:
      - PORT=3001
      # Устаревший метод аутентификации, оставлен для миграции
      - FLOWISE_USERNAME=\${FLOWISE_USERNAME}
      - FLOWISE_PASSWORD=\${FLOWISE_PASSWORD}
      # Новая система аутентификации (v3.0.1+)
      - APP_URL=https://flowise.\${DOMAIN_NAME}
      - JWT_AUTH_TOKEN_SECRET=\${JWT_AUTH_TOKEN_SECRET}
      - JWT_REFRESH_TOKEN_SECRET=\${JWT_REFRESH_TOKEN_SECRET}
      - JWT_TOKEN_EXPIRY_IN_MINUTES=60
      - JWT_REFRESH_TOKEN_EXPIRY_IN_MINUTES=129600
      - EXPRESS_SESSION_SECRET=\${EXPRESS_SESSION_SECRET}
      - TOKEN_HASH_SECRET=\${TOKEN_HASH_SECRET}
      - PASSWORD_SALT_HASH_ROUNDS=12
      # Redis конфигурация
      - REDIS_URL=redis://:\${REDIS_PASSWORD}@redis:6379
      - REDIS_USER=default
      - REDIS_PASSWORD=\${REDIS_PASSWORD}
      - FLOWISE_SECRETKEY_OVERWRITE=\${TOKEN_HASH_SECRET}
      - FLOWISE_CACHE=redis
      - SESSION_STORE=redis
      # PostgreSQL конфигурация
      - DATABASE_TYPE=postgres
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - DATABASE_USER=\${POSTGRES_USER}
      - DATABASE_PASSWORD=\${POSTGRES_PASSWORD}
      - DATABASE_NAME=\${POSTGRES_DB}
      - DATABASE_SSL=false
      - DATABASE_POOL_MIN=1
      - DATABASE_POOL_MAX=20
    volumes:
      - /opt/flowise:/root/.flowise
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --requirepass \${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - app-network

  postgres:
    image: ankane/pgvector:latest
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=\${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:
    external: true
EOL
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create file flowise-docker-compose.yaml.template"
    exit 1
  fi
else
  echo "Template flowise-docker-compose.yaml.template already exists"
fi

# Copy templates to working files
cp n8n-docker-compose.yaml.template n8n-docker-compose.yaml
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to copy n8n-docker-compose.yaml.template to working file"
  exit 1
fi

cp flowise-docker-compose.yaml.template flowise-docker-compose.yaml
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to copy flowise-docker-compose.yaml.template to working file"
  exit 1
fi

# Create Caddyfile
echo "Creating Caddyfile..."
cat > Caddyfile << EOL
n8n.${DOMAIN_NAME} {
    reverse_proxy n8n:5678
}

flowise.${DOMAIN_NAME} {
    reverse_proxy flowise:3001
}

pgadmin.${DOMAIN_NAME} {
    reverse_proxy pgadmin:80
}

qdrant.${DOMAIN_NAME} {
    # Проксируем API и встроенный веб-интерфейс Qdrant
    reverse_proxy qdrant:6333
}
EOL
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create Caddyfile"
  exit 1
fi

# Copy file to working directory
sudo cp Caddyfile /opt/n8n/
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to copy Caddyfile to /opt/n8n/"
  exit 1
fi

echo "✅ Templates and configuration files successfully created"
exit 0 