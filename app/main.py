import os
import socket
from datetime import datetime

from fastapi import FastAPI
from fastapi.responses import JSONResponse

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

app = FastAPI(
    title="EKS FastAPI Demo",
    description="Production-grade FastAPI on Amazon EKS",
    version=APP_VERSION,
)

@app.get("/health", tags=["observability"])
async def health():
    """Liveness probe — is the process alive?"""
    return JSONResponse(
        status_code=200,
        content={"status": "healthy", "timestamp": datetime.utcnow().isoformat()},
    )

@app.get("/ready", tags=["observability"])
async def ready():
    """Readiness probe — is the app ready to serve traffic?"""
    return JSONResponse(
        status_code=200,
        content={"status": "ready", "timestamp": datetime.utcnow().isoformat()},
    )

@app.get("/", tags=["info"])
async def root():
    """Returns app version, hostname (pod name) and environment."""
    return {
        "message": "Hello from EKS! 🚀",
        "version": APP_VERSION,
        "hostname": socket.gethostname(),
        "environment": ENVIRONMENT,
        "timestamp": datetime.utcnow().isoformat(),
    }

@app.get("/info", tags=["info"])
async def info():
    """Extended runtime information."""
    return {
        "app": "eks-fastapi-demo",
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "hostname": socket.gethostname(),
        "python_pid": os.getpid(),
    }
