#!/bin/bash

# Network Automation GitOps Platform - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "🔧 Deploying Network Automation GitOps Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
print_status "Python version: $PYTHON_VERSION"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

print_status "Docker is installed ✓"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git first."
    exit 1
fi

print_status "Git is installed ✓"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    print_status "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cat > .env << EOF
# Network Automation GitOps Platform Configuration
APP_ENV=development
SECRET_KEY=your-secret-key-here
API_PORT=8000
API_HOST=0.0.0.0

# Database Configuration
DATABASE_URL=postgresql://gitops:gitops_password@localhost:5432/network_gitops
REDIS_URL=redis://localhost:6379/0

# Git Configuration
GIT_USERNAME=your-git-username
GIT_EMAIL=your-email@example.com
GIT_DEFAULT_BRANCH=main

# Network Device Configuration
NETWORK_DEVICE_USERNAME=admin
NETWORK_DEVICE_PASSWORD=your-device-password
DEFAULT_DEVICE_TIMEOUT=30

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=logs/gitops.log

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_PATH=backups/
BACKUP_RETENTION_DAYS=30

# Security Configuration
ENABLE_TLS=false
TLS_CERT_PATH=certs/
TLS_KEY_PATH=certs/
EOF
    print_warning ".env file created. Please edit it with your network automation configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs backups configs devices temp

# Start supporting services with Docker
print_status "Starting supporting services (PostgreSQL, Redis)..."
docker run -d \
    --name gitops-postgres \
    -e POSTGRES_DB=network_gitops \
    -e POSTGRES_USER=gitops \
    -e POSTGRES_PASSWORD=gitops_password \
    -p 5432:5432 \
    -v gitops_data:/var/lib/postgresql/data \
    postgres:15-alpine

docker run -d \
    --name gitops-redis \
    -p 6379:6379 \
    -v gitops_redis:/data \
    redis:7.0-alpine

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Run database migrations
print_status "Running database migrations..."
python3 -m alembic upgrade head 2>/dev/null || print_warning "No migrations found, skipping"

# Create sample network configurations
print_status "Creating sample network configurations..."
cat > configs/sample-router-config.yaml << EOF
# Sample Router Configuration
device:
  name: "sample-router-01"
  type: "router"
  vendor: "cisco"
  model: "ISR4451"

interfaces:
  GigabitEthernet0/0/0:
    description: "WAN Interface"
    ip_address: "192.168.1.1"
    subnet_mask: "255.255.255.0"
    enabled: true

  GigabitEthernet0/0/1:
    description: "LAN Interface"
    ip_address: "10.0.0.1"
    subnet_mask: "255.255.255.0"
    enabled: true

routing:
  static_routes:
    - destination: "0.0.0.0"
      netmask: "0.0.0.0"
      next_hop: "192.168.1.254"

  ospf:
    enabled: true
    process_id: 1
    router_id: "10.0.0.1"
    networks:
      - network: "10.0.0.0"
        wildcard: "0.0.0.255"
        area: 0

security:
  access_lists:
    - name: "WAN_ACCESS"
      entries:
        - action: "permit"
          protocol: "tcp"
          source: "any"
          destination: "any"
          destination_port: "80"
        - action: "permit"
          protocol: "tcp"
          source: "any"
          destination: "any"
          destination_port: "443"
EOF

print_status "Sample configuration created: configs/sample-router-config.yaml"

# Test the application
print_status "Testing Network Automation GitOps Platform..."
python3 -c "import main; print('✅ Application imports successfully')"

# Start the Network Automation GitOps Platform
print_status "Starting Network Automation GitOps Platform..."
nohup python3 main.py > logs/gitops.log 2>&1 &
GITOPS_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "✅ Network Automation GitOps Platform is running successfully!"
    print_status "🔧 GitOps Dashboard: http://localhost:8000"
    print_status "❤️  Health Check: http://localhost:8000/health"
    print_status "📚 API Documentation: http://localhost:8000/docs"
    print_status ""
    print_status "🔧 API Endpoints:"
    print_status "   GET  /api/v1/configs      - List network configurations"
    print_status "   POST /api/v1/configs      - Create network configuration"
    print_status "   POST /api/v1/repositories  - Add Git repository"
    print_status "   POST /api/v1/deploy/{id}  - Deploy configuration"
    print_status "   GET  /api/v1/git/status   - Git repository status"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/gitops.log"
    exit 1
fi

print_status "🎉 Deployment completed successfully!"
print_status ""
print_status "📞 Support Contact:"
print_status "   Email: bgside2368@gmail.com"
print_status "   LinkedIn: https://www.linkedin.com/in/hex41414141"
print_status "   Phone: +963-986-956-140"
print_status ""
print_status "🔧 Useful commands:"
print_status "   Stop platform: kill $GITOPS_PID"
print_status "   View logs: tail -f logs/gitops.log"
print_status "   Restart: python3 main.py"
print_status "   Stop services: docker stop gitops-postgres gitops-redis"
print_status "   Remove services: docker rm gitops-postgres gitops-redis"

# Save PID for cleanup
echo $GITOPS_PID > .gitops.pid
print_status "Process ID saved to .gitops.pid"

print_status ""
print_status "🚀 Network Automation GitOps Platform Features:"
print_status "   🔧 Infrastructure as Code for Networks"
print_status "   📦 Configuration Version Control"
print_status "   🚀 Automated Device Deployment"
print_status "   🔄 Git-Based Configuration Management"
print_status "   📊 Deployment History & Rollback"
print_status "   🌐 Multi-Vendor Network Support"
print_status "   🔒 Secure Configuration Management"
