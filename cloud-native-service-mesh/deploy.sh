#!/bin/bash

# Cloud-Native Service Mesh Controller - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "🔗 Deploying Cloud-Native Service Mesh Controller..."

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
print_status "Building Cloud-Native Service Mesh Controller..."
go build -o bin/service-mesh-controller .

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    echo "Creating basic .env file for Service Mesh Controller"
    cat > .env << EOF
# Service Mesh Controller Configuration
PORT=8080
DEBUG=true
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgres://mesh:mesh_password@localhost:5432/service_mesh?sslmode=disable

# JWT Configuration
JWT_SECRET=your-jwt-secret-key-here
JWT_EXPIRY=24h

# Istio Configuration
ISTIO_NAMESPACE=istio-system
ISTIO_GATEWAY=istio-gateway
EOF
    print_warning ".env file created. Please edit it with your configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data certs

# Start PostgreSQL database if using Docker
print_status "Starting PostgreSQL database..."
docker run -d \
    --name mesh-postgres \
    -e POSTGRES_DB=service_mesh \
    -e POSTGRES_USER=mesh \
    -e POSTGRES_PASSWORD=mesh_password \
    -p 5432:5432 \
    -v mesh_data:/var/lib/postgresql/data \
    postgres:15-alpine

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
sleep 10

# Run database migrations (if migration tool exists)
print_status "Running database migrations..."
go run cmd/migrate/main.go up 2>/dev/null || print_warning "No migration command found, skipping migrations"

# Start Istio service mesh (if available)
print_status "Checking Istio service mesh..."
if command -v istioctl &> /dev/null; then
    print_status "Istio CLI found, checking service mesh status..."
    istioctl version 2>/dev/null || print_warning "Istio not installed, skipping service mesh setup"
else
    print_warning "Istio CLI not found, install Istio for full service mesh functionality"
fi

# Start the Service Mesh Controller
print_status "Starting Cloud-Native Service Mesh Controller..."
nohup ./bin/service-mesh-controller > logs/service-mesh-controller.log 2>&1 &
CONTROLLER_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_status "✅ Cloud-Native Service Mesh Controller is running successfully!"
    print_status "🔗 Service Mesh Dashboard: http://localhost:8080"
    print_status "❤️  Health Check: http://localhost:8080/health"
    print_status "📚 API Documentation: http://localhost:8080/swagger"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/service-mesh-controller.log"
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
print_status "   Stop controller: kill $CONTROLLER_PID"
print_status "   View logs: tail -f logs/service-mesh-controller.log"
print_status "   Restart: ./bin/service-mesh-controller"
print_status "   Stop database: docker stop mesh-postgres"
print_status "   Remove database: docker rm mesh-postgres"

# Save PID for cleanup
echo $CONTROLLER_PID > .service-mesh-controller.pid
print_status "Process ID saved to .service-mesh-controller.pid"
