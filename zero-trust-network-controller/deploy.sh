#!/bin/bash

# Zero Trust Network Controller - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "🛡️ Deploying Zero Trust Network Controller..."

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
print_status "Building Zero Trust Network Controller..."
go build -o bin/ztna-controller ./main.go

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cp .env.example .env 2>/dev/null || echo "No .env.example found, creating basic .env"
    print_warning ".env file created. Please edit it with your configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data certs

# Start PostgreSQL database if using Docker
print_status "Starting PostgreSQL database..."
docker run -d \
    --name ztna-postgres \
    -e POSTGRES_DB=ztna \
    -e POSTGRES_USER=ztna \
    -e POSTGRES_PASSWORD=ztna_password \
    -p 5432:5432 \
    -v ztna_data:/var/lib/postgresql/data \
    postgres:15-alpine

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
sleep 10

# Run database migrations
print_status "Running database migrations..."
go run cmd/migrate/main.go up 2>/dev/null || print_warning "No migration command found, skipping migrations"

# Start the Zero Trust Network Controller
print_status "Starting Zero Trust Network Controller..."
nohup ./bin/ztna-controller > logs/ztna-controller.log 2>&1 &
CONTROLLER_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_status "✅ Zero Trust Network Controller is running successfully!"
    print_status "🛡️ Admin Dashboard: http://localhost:8080"
    print_status "❤️  Health Check: http://localhost:8080/health"
    print_status "📚 API Documentation: http://localhost:8080/swagger"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/ztna-controller.log"
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
print_status "   View logs: tail -f logs/ztna-controller.log"
print_status "   Restart: ./bin/ztna-controller"
print_status "   Stop database: docker stop ztna-postgres"
print_status "   Remove database: docker rm ztna-postgres"

# Save PID for cleanup
echo $CONTROLLER_PID > .ztna-controller.pid
print_status "Process ID saved to .ztna-controller.pid"
