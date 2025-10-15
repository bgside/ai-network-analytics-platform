#!/usr/bin/env python3

"""
Network Automation GitOps Platform - Main Application
Author: Ali Emad SALEH
Contact: bgside2368@gmail.com
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Optional
import asyncio
import json
import os
import subprocess
import yaml
from datetime import datetime
import uuid

app = FastAPI(
    title="Network Automation GitOps Platform",
    description="Infrastructure as Code platform for network automation with GitOps workflows",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage (in production, use a database)
network_configs = {}
deployment_history = []
git_repositories = {}

class NetworkConfig(BaseModel):
    id: str
    name: str
    description: str
    config_type: str  # router, switch, firewall, etc.
    vendor: str       # cisco, juniper, arista, etc.
    model: str
    configuration: Dict
    version: str
    status: str = "draft"
    created_at: str
    updated_at: str

class GitRepository(BaseModel):
    id: str
    name: str
    url: str
    branch: str = "main"
    automation_path: str = "network-configs"
    last_sync: Optional[str] = None
    status: str = "active"

class Deployment(BaseModel):
    id: str
    config_id: str
    target_device: str
    status: str  # pending, running, success, failed
    started_at: str
    completed_at: Optional[str] = None
    logs: List[str] = []
    error_message: Optional[str] = None

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "network-automation-gitops",
        "timestamp": datetime.utcnow().isoformat(),
        "total_configs": len(network_configs),
        "total_deployments": len(deployment_history)
    }

@app.post("/api/v1/configs")
async def create_network_config(config: NetworkConfig):
    """Create a new network configuration"""
    config.id = str(uuid.uuid4())
    config.created_at = datetime.utcnow().isoformat()
    config.updated_at = config.created_at
    config.status = "draft"

    network_configs[config.id] = config

    return {
        "message": "Network configuration created successfully",
        "config": config
    }

@app.get("/api/v1/configs")
async def get_network_configs():
    """Get all network configurations"""
    return {
        "configs": list(network_configs.values()),
        "total": len(network_configs)
    }

@app.get("/api/v1/configs/{config_id}")
async def get_network_config(config_id: str):
    """Get a specific network configuration"""
    if config_id not in network_configs:
        raise HTTPException(status_code=404, detail="Configuration not found")

    return network_configs[config_id]

@app.put("/api/v1/configs/{config_id}")
async def update_network_config(config_id: str, updated_config: NetworkConfig):
    """Update a network configuration"""
    if config_id not in network_configs:
        raise HTTPException(status_code=404, detail="Configuration not found")

    updated_config.id = config_id
    updated_config.updated_at = datetime.utcnow().isoformat()
    network_configs[config_id] = updated_config

    return {
        "message": "Network configuration updated successfully",
        "config": updated_config
    }

@app.post("/api/v1/repositories")
async def add_git_repository(repo: GitRepository):
    """Add a Git repository for configuration management"""
    repo.id = str(uuid.uuid4())
    git_repositories[repo.id] = repo

    return {
        "message": "Git repository added successfully",
        "repository": repo
    }

@app.get("/api/v1/repositories")
async def get_git_repositories():
    """Get all Git repositories"""
    return {
        "repositories": list(git_repositories.values()),
        "total": len(git_repositories)
    }

@app.post("/api/v1/deploy/{config_id}")
async def deploy_configuration(config_id: str, target_device: str, background_tasks: BackgroundTasks):
    """Deploy a network configuration to a target device"""
    if config_id not in network_configs:
        raise HTTPException(status_code=404, detail="Configuration not found")

    deployment = Deployment(
        id=str(uuid.uuid4()),
        config_id=config_id,
        target_device=target_device,
        status="pending",
        started_at=datetime.utcnow().isoformat()
    )

    deployment_history.append(deployment)
    background_tasks.add_task(run_deployment, deployment.id, config_id, target_device)

    return {
        "message": "Deployment started",
        "deployment_id": deployment.id,
        "status": "pending"
    }

@app.get("/api/v1/deployments")
async def get_deployments():
    """Get all deployment history"""
    return {
        "deployments": deployment_history,
        "total": len(deployment_history)
    }

@app.get("/api/v1/deployments/{deployment_id}")
async def get_deployment(deployment_id: str):
    """Get a specific deployment"""
    for deployment in deployment_history:
        if deployment.id == deployment_id:
            return deployment

    raise HTTPException(status_code=404, detail="Deployment not found")

async def run_deployment(deployment_id: str, config_id: str, target_device: str):
    """Background task to run network configuration deployment"""
    # Find and update deployment
    deployment = None
    for d in deployment_history:
        if d.id == deployment_id:
            deployment = d
            break

    if not deployment:
        return

    deployment.status = "running"
    deployment.logs.append(f"[{datetime.utcnow().isoformat()}] Starting deployment to {target_device}")

    try:
        # Simulate deployment process
        await asyncio.sleep(2)

        config = network_configs[config_id]
        deployment.logs.append(f"[{datetime.utcnow().isoformat()}] Applying configuration: {config.name}")

        # Simulate device connection and configuration push
        await asyncio.sleep(3)

        deployment.logs.append(f"[{datetime.utcnow().isoformat()}] Configuration applied successfully")
        deployment.logs.append(f"[{datetime.utcnow().isoformat()}] Verifying configuration on {target_device}")

        await asyncio.sleep(2)

        deployment.status = "success"
        deployment.completed_at = datetime.utcnow().isoformat()
        deployment.logs.append(f"[{deployment.completed_at}] Deployment completed successfully")

    except Exception as e:
        deployment.status = "failed"
        deployment.completed_at = datetime.utcnow().isoformat()
        deployment.error_message = str(e)
        deployment.logs.append(f"[{deployment.completed_at}] Deployment failed: {str(e)}")

@app.post("/api/v1/git/sync")
async def sync_git_repository(repo_id: str):
    """Sync configurations from Git repository"""
    if repo_id not in git_repositories:
        raise HTTPException(status_code=404, detail="Repository not found")

    repo = git_repositories[repo_id]

    try:
        # Simulate git pull operation
        deployment_logs = []
        deployment_logs.append(f"[{datetime.utcnow().isoformat()}] Starting Git sync for {repo.name}")

        # In a real implementation, this would:
        # 1. Clone or pull from the Git repository
        # 2. Parse network configuration files
        # 3. Validate configurations
        # 4. Update local configuration store

        deployment_logs.append(f"[{datetime.utcnow().isoformat()}] Pulling from {repo.url}:{repo.branch}")
        deployment_logs.append(f"[{datetime.utcnow().isoformat()}] Parsing configuration files")
        deployment_logs.append(f"[{datetime.utcnow().isoformat()}] Validating configurations")
        deployment_logs.append(f"[{datetime.utcnow().isoformat()}] Sync completed successfully")

        # Update last sync time
        repo.last_sync = datetime.utcnow().isoformat()

        return {
            "message": "Git sync completed successfully",
            "repository": repo.name,
            "logs": deployment_logs,
            "last_sync": repo.last_sync
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Git sync failed: {str(e)}")

@app.get("/api/v1/git/status")
async def get_git_status():
    """Get Git repository status"""
    return {
        "repositories": list(git_repositories.values()),
        "total_repositories": len(git_repositories),
        "last_updates": [
            {
                "repository": repo.name,
                "last_sync": repo.last_sync,
                "status": repo.status
            }
            for repo in git_repositories.values()
        ]
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Network Automation GitOps Platform...")
    print("🔧 API Documentation: http://localhost:8000/docs")
    print("❤️  Health Check: http://localhost:8000/health")
    print("📞 Support Contact: bgside2368@gmail.com")

    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
