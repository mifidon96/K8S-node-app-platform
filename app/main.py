import os
import socket
from fastapi import FastAPI

app = FastAPI()
APP_ENV = os.getenv("APP_ENV", "unknown")
APP_MESSAGE = os.getenv("APP_MESSAGE", "hello from k8s")

@app.get("/")
def root():
    return {"message": APP_MESSAGE, "env": APP_ENV, "pod": socket.gethostname()}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/ready")
def ready():
    return {"status": "ready"}
