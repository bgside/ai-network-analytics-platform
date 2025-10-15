#!/bin/bash

# Intelligent Network Optimizer - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "🧠 Deploying Intelligent Network Optimizer..."

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
print_status "Building Intelligent Network Optimizer..."
go build -o bin/network-optimizer .

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cat > .env << EOF
# Intelligent Network Optimizer Configuration
PORT=8080
DEBUG=true
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgres://optimizer:optimizer_password@localhost:5432/network_optimizer?sslmode=disable

# JWT Configuration
JWT_SECRET=your-jwt-secret-key-here
JWT_EXPIRY=24h

# Machine Learning Configuration
ML_MODEL_PATH=models/
ML_TRAINING_ENABLED=true
ML_PREDICTION_INTERVAL=300

# Network Monitoring Configuration
MONITORING_INTERVAL=60
BANDWIDTH_THRESHOLD=80
LATENCY_THRESHOLD=100
PACKET_LOSS_THRESHOLD=5

# Optimization Configuration
AUTO_OPTIMIZATION=true
OPTIMIZATION_INTERVAL=600
MIN_SAMPLE_SIZE=100

# Alert Configuration
ALERT_EMAIL_ENABLED=false
ALERT_EMAIL_RECIPIENTS=admin@company.com
SLACK_WEBHOOK_URL=

# Prometheus Configuration
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090
METRICS_PATH=/metrics
EOF
    print_warning ".env file created. Please edit it with your network optimization configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data models configs reports

# Start PostgreSQL database if using Docker
print_status "Starting PostgreSQL database..."
docker run -d \
    --name optimizer-postgres \
    -e POSTGRES_DB=network_optimizer \
    -e POSTGRES_USER=optimizer \
    -e POSTGRES_PASSWORD=optimizer_password \
    -p 5432:5432 \
    -v optimizer_data:/var/lib/postgresql/data \
    postgres:15-alpine

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
sleep 10

# Run database migrations (if migration tool exists)
print_status "Running database migrations..."
go run cmd/migrate/main.go up 2>/dev/null || print_warning "No migration command found, skipping migrations"

# Create sample ML model configuration
print_status "Creating sample ML model configuration..."
cat > models/model-config.json << EOF
{
  "model_name": "network_performance_predictor",
  "model_type": "regression",
  "algorithm": "random_forest",
  "features": [
    "bandwidth_utilization",
    "latency_p95",
    "packet_loss_rate",
    "error_rate",
    "connection_count",
    "cpu_usage",
    "memory_usage"
  ],
  "target": "performance_score",
  "training_parameters": {
    "n_estimators": 100,
    "max_depth": 10,
    "min_samples_split": 5,
    "test_size": 0.2,
    "random_state": 42
  },
  "model_metrics": {
    "accuracy": 0.0,
    "precision": 0.0,
    "recall": 0.0,
    "f1_score": 0.0,
    "last_trained": null
  }
}
EOF

print_status "Sample ML model configuration created: models/model-config.json"

# Start the Intelligent Network Optimizer
print_status "Starting Intelligent Network Optimizer..."
nohup ./bin/network-optimizer > logs/network-optimizer.log 2>&1 &
OPTIMIZER_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_status "✅ Intelligent Network Optimizer is running successfully!"
    print_status "🧠 Network Optimizer Dashboard: http://localhost:8080"
    print_status "❤️  Health Check: http://localhost:8080/health"
    print_status "📚 API Documentation: http://localhost:8080/swagger"
    print_status ""
    print_status "🔧 API Endpoints:"
    print_status "   GET  /api/v1/optimization  - Current optimization status"
    print_status "   POST /api/v1/optimization  - Trigger optimization"
    print_status "   GET  /api/v1/predictions   - Network performance predictions"
    print_status "   GET  /api/v1/models        - ML model information"
    print_status "   GET  /api/v1/metrics       - Network performance metrics"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/network-optimizer.log"
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
print_status "   Stop optimizer: kill $OPTIMIZER_PID"
print_status "   View logs: tail -f logs/network-optimizer.log"
print_status "   Restart: ./bin/network-optimizer"
print_status "   Stop database: docker stop optimizer-postgres"
print_status "   Remove database: docker rm optimizer-postgres"

# Save PID for cleanup
echo $OPTIMIZER_PID > .network-optimizer.pid
print_status "Process ID saved to .network-optimizer.pid"

print_status ""
print_status "🚀 Intelligent Network Optimizer Features:"
print_status "   🧠 AI-Powered Network Optimization"
print_status "   📊 Predictive Performance Analytics"
print_status "   🔄 Automated Configuration Tuning"
print_status "   📈 Machine Learning Model Training"
print_status "   🚨 Intelligent Alert System"
print_status "   📋 Performance Reporting & Insights"
print_status "   🌐 Multi-Vendor Network Support"
