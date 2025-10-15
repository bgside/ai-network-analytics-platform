#!/bin/bash

# Edge Computing Orchestrator - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "⚡ Deploying Edge Computing Orchestrator..."

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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. Install kubectl for full Kubernetes integration."
fi

print_status "Docker is installed ✓"

# Download Go dependencies
print_status "Downloading Go dependencies..."
go mod download

# Build the application
print_status "Building Edge Computing Orchestrator..."
go build -o bin/edge-orchestrator .

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cat > .env << EOF
# Edge Computing Orchestrator Configuration
PORT=8080
DEBUG=true
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgres://edge:edge_password@localhost:5432/edge_orchestrator?sslmode=disable

# JWT Configuration
JWT_SECRET=your-jwt-secret-key-here
JWT_EXPIRY=24h

# Kubernetes Configuration
KUBECONFIG_PATH=~/.kube/config
NAMESPACE=edge-computing
CLUSTER_NAME=edge-cluster

# Edge Node Configuration
EDGE_NODES_AUTO_DISCOVERY=true
EDGE_NODES_CONFIG_PATH=config/edge-nodes.yaml

# Monitoring Configuration
METRICS_ENABLED=true
METRICS_PORT=9090
PROMETHEUS_GATEWAY=prometheus-gateway:9091
EOF
    print_warning ".env file created. Please edit it with your edge computing configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data config certs edge-nodes

# Start PostgreSQL database if using Docker
print_status "Starting PostgreSQL database..."
docker run -d \
    --name edge-postgres \
    -e POSTGRES_DB=edge_orchestrator \
    -e POSTGRES_USER=edge \
    -e POSTGRES_PASSWORD=edge_password \
    -p 5432:5432 \
    -v edge_data:/var/lib/postgresql/data \
    postgres:15-alpine

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
sleep 10

# Run database migrations (if migration tool exists)
print_status "Running database migrations..."
go run cmd/migrate/main.go up 2>/dev/null || print_warning "No migration command found, skipping migrations"

# Check Kubernetes cluster connectivity
print_status "Checking Kubernetes cluster connectivity..."
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info > /dev/null 2>&1; then
        print_status "✅ Kubernetes cluster is accessible"
        kubectl get nodes > /dev/null 2>&1 && print_status "✅ Edge nodes detected" || print_warning "No edge nodes found in cluster"
    else
        print_warning "❌ Kubernetes cluster not accessible. Install and configure kubectl for full functionality."
    fi
else
    print_warning "kubectl not found. Install kubectl for Kubernetes integration."
fi

# Start the Edge Computing Orchestrator
print_status "Starting Edge Computing Orchestrator..."
nohup ./bin/edge-orchestrator > logs/edge-orchestrator.log 2>&1 &
ORCHESTRATOR_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_status "✅ Edge Computing Orchestrator is running successfully!"
    print_status "⚡ Edge Orchestrator Dashboard: http://localhost:8080"
    print_status "❤️  Health Check: http://localhost:8080/health"
    print_status "📚 API Documentation: http://localhost:8080/swagger"
    print_status ""
    print_status "🔧 API Endpoints:"
    print_status "   GET  /api/v1/edge-nodes   - List edge nodes"
    print_status "   POST /api/v1/applications - Deploy application"
    print_status "   GET  /api/v1/metrics      - Edge metrics"
    print_status "   GET  /api/v1/health       - System health"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/edge-orchestrator.log"
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
print_status "   Stop orchestrator: kill $ORCHESTRATOR_PID"
print_status "   View logs: tail -f logs/edge-orchestrator.log"
print_status "   Restart: ./bin/edge-orchestrator"
print_status "   Stop database: docker stop edge-postgres"
print_status "   Remove database: docker rm edge-postgres"

# Save PID for cleanup
echo $ORCHESTRATOR_PID > .edge-orchestrator.pid
print_status "Process ID saved to .edge-orchestrator.pid"

print_status ""
print_status "🚀 Edge Computing Orchestrator Features:"
print_status "   🌐 Multi-Edge Node Management"
print_status "   📦 Application Deployment & Scaling"
print_status "   📊 Real-time Performance Monitoring"
print_status "   🔄 Load Balancing Across Edge Nodes"
print_status "   ☸️ Kubernetes Integration"
print_status "   🔒 Secure Edge Communication"
