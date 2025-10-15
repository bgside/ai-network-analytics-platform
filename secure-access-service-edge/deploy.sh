#!/bin/bash

# Secure Access Service Edge (SASE) - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "🔒 Deploying Secure Access Service Edge (SASE) Platform..."

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

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install Go 1.21+ first."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
print_status "Go version: $GO_VERSION"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

print_status "Docker is installed ✓"

# Download Go dependencies
print_status "Downloading Go dependencies..."
go mod download

# Build the application
print_status "Building Secure Access Service Edge Platform..."
go build -o bin/sase-controller .

# Install Swag for API documentation
print_status "Installing Swag for API documentation..."
go install github.com/swaggo/swag/cmd/swag@latest

# Generate API documentation
print_status "Generating API documentation..."
swag init -g main.go -o docs/

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cat > .env << EOF
# Secure Access Service Edge Configuration
PORT=8080
DEBUG=true
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgres://sase:sase_password@localhost:5432/sase_platform?sslmode=disable

# JWT Configuration
JWT_SECRET=your-sase-jwt-secret-key-here
JWT_EXPIRY=24h

# SASE Gateway Configuration
SASE_GATEWAY_PORT=9443
SASE_IDENTITY_PROVIDER=internal
SASE_CERT_PATH=certs/sase.crt
SASE_KEY_PATH=certs/sase.key

# Security Policies
DEFAULT_SECURITY_POLICY=zero-trust
ENABLE_MICROSEGMENTATION=true
ENABLE_THREAT_PREVENTION=true
ENABLE_DATA_LOSS_PREVENTION=true

# Cloud Integration
AWS_REGION=us-west-2
AZURE_SUBSCRIPTION_ID=
GCP_PROJECT_ID=

# Monitoring and Analytics
ENABLE_CASB=true
ENABLE_SWG=true
ENABLE_ZTNA=true
ENABLE_FWaaS=true

# Compliance Configuration
GDPR_COMPLIANCE=true
HIPAA_COMPLIANCE=false
SOX_COMPLIANCE=false
PCI_DSS_COMPLIANCE=false

# Alert Configuration
ALERT_WEBHOOK_URL=
ALERT_EMAIL_RECIPIENTS=security@company.com
SLACK_SECURITY_CHANNEL=
EOF
    print_warning ".env file created. Please edit it with your SASE configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data certs policies reports

# Start PostgreSQL database if using Docker
print_status "Starting PostgreSQL database..."
docker run -d \
    --name sase-postgres \
    -e POSTGRES_DB=sase_platform \
    -e POSTGRES_USER=sase \
    -e POSTGRES_PASSWORD=sase_password \
    -p 5432:5432 \
    -v sase_data:/var/lib/postgresql/data \
    postgres:15-alpine

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
sleep 10

# Run database migrations (if migration tool exists)
print_status "Running database migrations..."
go run cmd/migrate/main.go up 2>/dev/null || print_warning "No migration command found, skipping migrations"

# Create sample security policies
print_status "Creating sample security policies..."
cat > policies/zero-trust-policy.yaml << EOF
# Zero Trust Security Policy
policy_name: "zero-trust-default"
description: "Default zero trust security policy for all access"
version: "1.0"

identity_verification:
  require_mfa: true
  require_device_cert: true
  require_user_cert: true
  session_timeout: 3600

network_security:
  microsegmentation: true
  east_west_inspection: true
  north_south_inspection: true
  threat_prevention: true

data_protection:
  dlp_enabled: true
  encryption_required: true
  watermarking: false

access_control:
  least_privilege: true
  just_in_time_access: true
  continuous_verification: true

monitoring:
  log_all_access: true
  alert_on_anomalies: true
  compliance_reporting: true
EOF

print_status "Sample security policy created: policies/zero-trust-policy.yaml"

# Start the Secure Access Service Edge Platform
print_status "Starting Secure Access Service Edge Platform..."
nohup ./bin/sase-controller > logs/sase-controller.log 2>&1 &
SASE_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_status "✅ Secure Access Service Edge Platform is running successfully!"
    print_status "🔒 SASE Dashboard: http://localhost:8080"
    print_status "❤️  Health Check: http://localhost:8080/health"
    print_status "📚 API Documentation: http://localhost:8080/swagger/index.html"
    print_status ""
    print_status "🔧 SASE Services:"
    print_status "   🌐 Secure Web Gateway (SWG)"
    print_status "   🛡️ Cloud Access Security Broker (CASB)"
    print_status "   🔐 Zero Trust Network Access (ZTNA)"
    print_status "   🔥 Firewall as a Service (FWaaS)"
    print_status "   📊 Security Analytics & Reporting"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/sase-controller.log"
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
print_status "   Stop SASE platform: kill $SASE_PID"
print_status "   View logs: tail -f logs/sase-controller.log"
print_status "   Restart: ./bin/sase-controller"
print_status "   Stop database: docker stop sase-postgres"
print_status "   Remove database: docker rm sase-postgres"

# Save PID for cleanup
echo $SASE_PID > .sase-controller.pid
print_status "Process ID saved to .sase-controller.pid"

print_status ""
print_status "🚀 Secure Access Service Edge Features:"
print_status "   🔒 Zero Trust Network Access (ZTNA)"
print_status "   🌐 Secure Web Gateway (SWG)"
print_status "   🛡️ Cloud Access Security Broker (CASB)"
print_status "   🔥 Firewall as a Service (FWaaS)"
print_status "   📊 Security Analytics & Compliance"
print_status "   🔐 Identity & Access Management"
print_status "   🌍 Global Edge Network"
print_status "   📱 Mobile & Endpoint Security"
