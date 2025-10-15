#!/bin/bash

# 5G Network Slicing Platform - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "📶 Deploying 5G Network Slicing Management Platform..."

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
    print_error "Python 3 is not installed. Please install Python 3.11+ first."
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
    print_warning ".env file created. Please edit it with your 5G infrastructure configuration."
fi

# Build Docker images
print_status "Building Docker images..."
docker-compose -f docker-compose.dev.yml build

# Start infrastructure services
print_status "Starting infrastructure services (PostgreSQL, Redis, Kafka, InfluxDB)..."
docker-compose -f docker-compose.dev.yml up -d postgres redis kafka influxdb grafana

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Run Django database migrations
print_status "Running Django database migrations..."
python manage.py migrate

# Create Django superuser if it doesn't exist
print_status "Creating Django superuser..."
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@5gslicing.local', 'admin123')" | python manage.py shell

# Collect static files
print_status "Collecting static files..."
python manage.py collectstatic --noinput

# Start Celery workers for async operations
print_status "Starting Celery workers..."
celery -A network_slicing worker -l info --detach

# Start the Django application
print_status "Starting 5G Network Slicing Platform..."
python manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &
DJANGO_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:8000/health/ > /dev/null 2>&1; then
    print_status "✅ 5G Network Slicing Platform is running successfully!"
    print_status "📶 Frontend Dashboard: http://localhost:8000"
    print_status "🔧 Django Admin: http://localhost:8000/admin"
    print_status "📚 API Documentation: http://localhost:8000/api/docs/"
    print_status "📊 Grafana Analytics: http://localhost:3001"
    print_status "❤️  Health Check: http://localhost:8000/health/"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View Django logs: tail -f django.log"
    print_status "View Docker logs: docker-compose -f docker-compose.dev.yml logs"
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
print_status "   Stop Django: kill $DJANGO_PID"
print_status "   View Django logs: tail -f django.log"
print_status "   Stop all services: docker-compose -f docker-compose.dev.yml down"
print_status "   Restart Celery: celery -A network_slicing worker -l info"

# Save PID for cleanup
echo $DJANGO_PID > .django.pid
print_status "Django Process ID saved to .django.pid"
