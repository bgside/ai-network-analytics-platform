#!/bin/bash

# IoT Network Management Hub - Deployment Script
# Author: Ali Emad SALEH
# Contact: bgside2368@gmail.com

set -e

echo "📡 Deploying IoT Network Management Hub..."

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
# IoT Network Management Hub Configuration
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here

# MQTT Configuration
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=
MQTT_PASSWORD=

# Database Configuration (Optional)
MONGODB_URL=mongodb://localhost:27017/iot_hub
REDIS_URL=redis://localhost:6379/0

# API Configuration
API_PORT=5000
API_HOST=0.0.0.0

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/iot_hub.log
EOF
    print_warning ".env file created. Please edit it with your IoT configuration."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs data devices backups

# Start supporting services with Docker
print_status "Starting supporting services (MongoDB, Redis, MQTT)..."
docker run -d \
    --name iot-mongodb \
    -e MONGO_INITDB_DATABASE=iot_hub \
    -p 27017:27017 \
    -v iot_data:/data/db \
    mongo:7.0

docker run -d \
    --name iot-redis \
    -p 6379:6379 \
    -v iot_redis:/data \
    redis:7.0-alpine

docker run -d \
    --name iot-mqtt \
    -p 1883:1883 \
    -p 9001:9001 \
    eclipse-mosquitto:2.0

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Create log file
print_status "Setting up logging..."
touch logs/iot_hub.log

# Test the application
print_status "Testing IoT Network Management Hub..."
python3 -c "import app; print('✅ Application imports successfully')"

# Start the IoT Network Management Hub
print_status "Starting IoT Network Management Hub..."
nohup python3 app.py > logs/iot_hub.log 2>&1 &
APP_PID=$!

# Wait for application to start
sleep 10

# Health check
print_status "Performing health check..."
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    print_status "✅ IoT Network Management Hub is running successfully!"
    print_status "📡 IoT Dashboard: http://localhost:5000"
    print_status "❤️  Health Check: http://localhost:5000/health"
    print_status "📚 API Documentation: http://localhost:5000/apidocs"
    print_status ""
    print_status "🔧 API Endpoints:"
    print_status "   GET  /api/v1/devices      - List all IoT devices"
    print_status "   POST /api/v1/devices      - Register new device"
    print_status "   GET  /api/v1/metrics      - Network metrics"
    print_status "   GET  /api/v1/alerts       - Active alerts"
else
    print_error "❌ Health check failed. Please check the logs."
    print_status "View logs: tail -f logs/iot_hub.log"
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
print_status "   Stop application: kill $APP_PID"
print_status "   View logs: tail -f logs/iot_hub.log"
print_status "   Restart: python3 app.py"
print_status "   Stop services: docker stop iot-mongodb iot-redis iot-mqtt"
print_status "   Remove services: docker rm iot-mongodb iot-redis iot-mqtt"

# Save PID for cleanup
echo $APP_PID > .iot-hub.pid
print_status "Process ID saved to .iot-hub.pid"

print_status ""
print_status "🚀 IoT Network Management Hub Features:"
print_status "   📱 Device Registration & Management"
print_status "   📊 Real-time Metrics & Monitoring"
print_status "   🚨 Alert System for Low Battery/Offline Devices"
print_status "   📡 MQTT Integration for Device Communication"
print_status "   💾 Historical Data Storage"
print_status "   🌐 RESTful API for Integration"
