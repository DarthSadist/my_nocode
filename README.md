# Cloud-Local n8n & Flowise Setup

Automated installation script for n8n and Flowise with reverse proxy server Caddy for secure access via HTTPS.

## Description

This repository contains scripts for automatic configuration of:

- **n8n** - a powerful open-source workflow automation platform
- **Flowise** - a tool for creating customizable AI flows
- **Redis** - in-memory data structure store used as a cache
- **PostgreSQL (with pgvector)** - database with vector extension for AI operations
- **pgAdmin 4** - web-based management tool for PostgreSQL
- **Caddy** - a modern web server with automatic HTTPS

The system is configured to work with your domain name and automatically obtains Let's Encrypt SSL certificates.

## Requirements

- Ubuntu 22.04 
- Domain name pointing to your server's IP address
- Server access with administrator rights (sudo)
- Open ports 80, 443 

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/miolamio/cloud-local-n8n-flowise.git && cd cloud-local-n8n-flowise
   ```

2. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the installation script:
   ```bash
   ./setup.sh
   ```

4. Follow the instructions in the terminal:
   - Enter your domain name (e.g., example.com)
   - Enter your email (will be used for n8n login and Let's Encrypt)

## What the installation script does

1. **System update** - updates the package list and installs necessary dependencies
2. **Docker installation** - installs Docker Engine and Docker Compose
3. **Directory setup** - creates n8n user and necessary directories
4. **Secret generation** - creates random passwords and encryption keys
5. **Configuration file creation** - generates docker-compose files and Caddyfile
6. **Firewall setup** - opens necessary ports
7. **Service launch** - starts Docker containers

## Accessing services

After installation completes, you will be able to access services at the following URLs:

- **n8n**: https://n8n.your-domain.xxx
- **Flowise**: https://flowise.your-domain.xxx
- **pgAdmin**: https://pgadmin.your-domain.xxx

Login credentials will be displayed at the end of the installation process.

### PostgreSQL Connection in pgAdmin

To connect to the PostgreSQL database from pgAdmin:

1. Login to pgAdmin using your email and generated password
2. Add a new server in pgAdmin with the following settings:
   - **Name**: Any name you prefer (e.g., "Local PostgreSQL")
   - **Connection tab**:
     - **Host**: postgres
     - **Port**: 5432
     - **Database**: flowise (default)
     - **Username**: flowise (default)
     - **Password**: The password generated during installation (check `.env` file)

### Connecting n8n to PostgreSQL

To connect n8n workflows to the PostgreSQL database, create a new credentials entry with the following details:

- **Host**: postgres
- **Port**: 5432
- **Database**: flowise (default)
- **Username**: flowise (default)
- **Password**: The password generated during installation (check `.env` file)

## Project structure

- `setup.sh` - main installation script
- `setup-files/` - directory with helper scripts:
  - `01-update-system.sh` - system update
  - `02-install-docker.sh` - Docker installation
  - `03-setup-directories.sh` - directory and user setup
  - `04-generate-secrets.sh` - secret key generation
  - `05-create-templates.sh` - configuration file creation
  - `06-setup-firewall.sh` - firewall setup
  - `07-start-services.sh` - service launch
- `n8n-docker-compose.yaml.template` - docker-compose template for n8n and Caddy
- `flowise-docker-compose.yaml.template` - docker-compose template for Flowise

## Managing services

### Restarting services

```bash
docker compose -f n8n-docker-compose.yaml restart
docker compose -f flowise-docker-compose.yaml restart
```

To restart specific services:

```bash
docker compose -f n8n-docker-compose.yaml restart n8n
docker compose -f n8n-docker-compose.yaml restart pgadmin
docker compose -f n8n-docker-compose.yaml restart redis postgres
```

### Stopping services

```bash
docker compose -f n8n-docker-compose.yaml down
docker compose -f flowise-docker-compose.yaml down
```

### Viewing logs

```bash
docker compose -f n8n-docker-compose.yaml logs
docker compose -f flowise-docker-compose.yaml logs
```

View logs for specific services:

```bash
docker compose -f n8n-docker-compose.yaml logs n8n
docker compose -f n8n-docker-compose.yaml logs pgadmin
docker compose -f n8n-docker-compose.yaml logs postgres
```

### Database Management

PostgreSQL database is accessible via pgAdmin at https://pgadmin.your-domain.xxx or directly using any PostgreSQL client:

```bash
docker exec -it postgres psql -U flowise -d flowise
```

## Security

- All services are accessible only via HTTPS with automatically renewed Let's Encrypt certificates
- Random passwords are created for n8n and Flowise
- Users are created with minimal necessary privileges

## Troubleshooting

- Check your domain's DNS records to ensure they point to the correct IP address
- Verify that ports 80 and 443 are open on your server
- View container logs to detect errors

## License

This project is distributed under the MIT License.

## Author

@codegeek# my_nocode
# my_nocode
