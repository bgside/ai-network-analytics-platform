#!/bin/bash

# AI-Powered Network Analytics Platform - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "🚀 Deploying AI-Powered Network Analytics Platform..."

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Docker and Docker Compose are installed ✓"

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
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file from template..."
    cp .env.example .env
    print_warning ".env file created. Please edit it with your configuration."
fi

# Build Docker images
print_status "Building Docker images..."
docker-compose -f docker-compose.dev.yml build

# Start infrastructure services
print_status "Starting infrastructure services (PostgreSQL, Redis, Kafka)..."
docker-compose -f docker-compose.dev.yml up -d postgres redis kafka

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Run database migrations
print_status "Running database migrations..."
python -m alembic upgrade head

# Start the main application
print_status "Starting AI Network Analytics Platform..."
docker-compose -f docker-compose.dev.yml up -d ai-analytics

# Wait for application to start
sleep 15

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "✅ AI Network Analytics Platform is running successfully!"
    print_status "📊 Dashboard: http://localhost:8000"
    print_status "📚 API Documentation: http://localhost:8000/docs"
    print_status "❤️  Health Check: http://localhost:8000/health"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: docker-compose -f docker-compose.dev.yml logs"
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
print_status "   Stop services: docker-compose -f docker-compose.dev.yml down"
print_status "   View logs: docker-compose -f docker-compose.dev.yml logs -f"
print_status "   Restart: docker-compose -f docker-compose.dev.yml restart"
