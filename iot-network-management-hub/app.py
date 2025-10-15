#!/usr/bin/env python3

"""
IoT Network Management Hub - Main Application
Author: Ali Emad SALEH
Contact: bgside2368@gmail.com
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import time
import uuid
from datetime import datetime
from typing import Dict, List, Optional

app = Flask(__name__)
CORS(app)

# In-memory storage for IoT devices (in production, use a database)
devices = {}
device_metrics = {}

class IoTDevice:
    def __init__(self, device_id: str, name: str, device_type: str, location: str):
        self.device_id = device_id
        self.name = name
        self.device_type = device_type
        self.location = location
        self.status = "offline"
        self.last_seen = None
        self.battery_level = 100
        self.signal_strength = 0
        self.created_at = datetime.utcnow().isoformat()

    def to_dict(self):
        return {
            "device_id": self.device_id,
            "name": self.name,
            "device_type": self.device_type,
            "location": self.location,
            "status": self.status,
            "last_seen": self.last_seen,
            "battery_level": self.battery_level,
            "signal_strength": self.signal_strength,
            "created_at": self.created_at
        }

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "iot-network-management-hub",
        "timestamp": datetime.utcnow().isoformat(),
        "total_devices": len(devices)
    })

@app.route('/api/v1/devices', methods=['GET'])
def get_devices():
    """Get all IoT devices"""
    return jsonify({
        "devices": [device.to_dict() for device in devices.values()],
        "total": len(devices)
    })

@app.route('/api/v1/devices', methods=['POST'])
def register_device():
    """Register a new IoT device"""
    data = request.get_json()

    if not data or not all(key in data for key in ['name', 'device_type', 'location']):
        return jsonify({"error": "Missing required fields: name, device_type, location"}), 400

    device_id = str(uuid.uuid4())
    device = IoTDevice(
        device_id=device_id,
        name=data['name'],
        device_type=data['device_type'],
        location=data['location']
    )

    devices[device_id] = device

    return jsonify({
        "message": "Device registered successfully",
        "device": device.to_dict()
    }), 201

@app.route('/api/v1/devices/<device_id>', methods=['GET'])
def get_device(device_id):
    """Get a specific IoT device"""
    if device_id not in devices:
        return jsonify({"error": "Device not found"}), 404

    return jsonify(devices[device_id].to_dict())

@app.route('/api/v1/devices/<device_id>/metrics', methods=['POST'])
def update_device_metrics(device_id):
    """Update device metrics (battery, signal, etc.)"""
    if device_id not in devices:
        return jsonify({"error": "Device not found"}), 404

    data = request.get_json()
    device = devices[device_id]

    # Update device status and metrics
    device.status = "online"
    device.last_seen = datetime.utcnow().isoformat()

    if 'battery_level' in data:
        device.battery_level = max(0, min(100, data['battery_level']))

    if 'signal_strength' in data:
        device.signal_strength = max(0, min(100, data['signal_strength']))

    # Store metrics for historical tracking
    metrics_entry = {
        "device_id": device_id,
        "timestamp": device.last_seen,
        "battery_level": device.battery_level,
        "signal_strength": device.signal_strength,
        "status": device.status
    }

    if device_id not in device_metrics:
        device_metrics[device_id] = []
    device_metrics[device_id].append(metrics_entry)

    # Keep only last 1000 metrics per device
    if len(device_metrics[device_id]) > 1000:
        device_metrics[device_id] = device_metrics[device_id][-1000:]

    return jsonify({
        "message": "Metrics updated successfully",
        "device": device.to_dict()
    })

@app.route('/api/v1/devices/<device_id>/command', methods=['POST'])
def send_command(device_id):
    """Send a command to an IoT device"""
    if device_id not in devices:
        return jsonify({"error": "Device not found"}), 404

    data = request.get_json()
    if not data or 'command' not in data:
        return jsonify({"error": "Command field is required"}), 400

    command = {
        "device_id": device_id,
        "command": data['command'],
        "parameters": data.get('parameters', {}),
        "timestamp": datetime.utcnow().isoformat(),
        "status": "sent"
    }

    # In a real implementation, this would be sent to the device via MQTT or other protocol
    return jsonify({
        "message": "Command sent successfully",
        "command": command
    })

@app.route('/api/v1/metrics', methods=['GET'])
def get_network_metrics():
    """Get overall network metrics"""
    total_devices = len(devices)
    online_devices = sum(1 for device in devices.values() if device.status == "online")
    offline_devices = total_devices - online_devices

    avg_battery = 0
    avg_signal = 0

    if total_devices > 0:
        online_devices_list = [d for d in devices.values() if d.status == "online"]
        if online_devices_list:
            avg_battery = sum(d.battery_level for d in online_devices_list) / len(online_devices_list)
            avg_signal = sum(d.signal_strength for d in online_devices_list) / len(online_devices_list)

    return jsonify({
        "network_overview": {
            "total_devices": total_devices,
            "online_devices": online_devices,
            "offline_devices": offline_devices,
            "network_status": "healthy" if online_devices > 0 else "degraded"
        },
        "averages": {
            "battery_level": round(avg_battery, 2),
            "signal_strength": round(avg_signal, 2)
        },
        "timestamp": datetime.utcnow().isoformat()
    })

@app.route('/api/v1/alerts', methods=['GET'])
def get_alerts():
    """Get active alerts for the IoT network"""
    alerts = []

    # Check for low battery devices
    for device in devices.values():
        if device.battery_level < 20:
            alerts.append({
                "id": str(uuid.uuid4()),
                "type": "low_battery",
                "severity": "warning",
                "device_id": device.device_id,
                "device_name": device.name,
                "message": f"Device {device.name} has low battery ({device.battery_level}%)",
                "timestamp": datetime.utcnow().isoformat()
            })

        # Check for offline devices (not seen for more than 5 minutes)
        if device.status == "offline":
            alerts.append({
                "id": str(uuid.uuid4()),
                "type": "device_offline",
                "severity": "critical",
                "device_id": device.device_id,
                "device_name": device.name,
                "message": f"Device {device.name} is offline",
                "timestamp": datetime.utcnow().isoformat()
            })

    return jsonify({
        "alerts": alerts,
        "total_alerts": len(alerts)
    })

if __name__ == '__main__':
    print("🚀 Starting IoT Network Management Hub...")
    print("📡 API Documentation available at: http://localhost:5000/apidocs")
    print("❤️  Health Check: http://localhost:5000/health")
    print("📞 Support Contact: bgside2368@gmail.com")

    app.run(host='0.0.0.0', port=5000, debug=True)
