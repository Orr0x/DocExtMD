# Markdown Extractor - Docling Model API Deployment Guide

## Overview
Deploy a Docling-based document-to-markdown conversion API service on a VPS. This service will be accessible from local development machines for testing and integration.

## Prerequisites
- VPS access: root@31.97.115.105
- Ubuntu 24.04 LTS (already installed)
- KVM 2 plan: 2 CPU cores, 8GB RAM, 100GB storage
- Docker and Docker Compose (to be installed)

---

## Step 1: Install Docker and Docker Compose

SSH into the VPS and install required software:

```bash
# Update package list
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify Docker installation
docker --version
docker-compose --version
```

---

## Step 2: Create Project Structure

Create directory structure for the Markdown Extractor service:

```bash
# Create main project directory
mkdir -p ~/markdown-extractor

# Navigate to project directory
cd ~/markdown-extractor

# Create subdirectories
mkdir -p models api
```

---

## Step 3: Download Docling Model

Download the Docling GGUF model (450MB, Q8_0 quantization):

```bash
# Navigate to models directory
cd ~/markdown-extractor/models

# Download the model from HuggingFace
wget https://huggingface.co/gguf-org/docling-gguf/resolve/main/docling-q8_0.gguf

# Verify download
ls -lh docling-q8_0.gguf

# Return to project root
cd ~/markdown-extractor
```

---

## Step 4: Create Dockerfile

Create a Dockerfile to build the Docling API service container:

```bash
# Create Dockerfile in project root
cat > ~/markdown-extractor/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    python-multipart==0.0.6 \
    docling

# Copy API code
COPY api/main.py /app/main.py

# Expose port
EXPOSE 5000

# Start the API server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
EOF
```

---

## Step 5: Create FastAPI Application

Create the main API application file:

```bash
# Create main.py in api directory
cat > ~/markdown-extractor/api/main.py << 'EOF'
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from docling.document_converter import DocumentConverter
import tempfile
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Markdown Extractor API",
    description="Convert documents (PDF, DOCX, images) to Markdown using Docling",
    version="1.0.0"
)

# Add CORS middleware to allow requests from local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Docling converter
# Note: The model path can be configured via environment variable
model_path = os.getenv("MODEL_PATH", "/models/docling-q8_0.gguf")
logger.info(f"Initializing Docling with model: {model_path}")

try:
    converter = DocumentConverter()
    logger.info("Docling converter initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Docling: {e}")
    converter = None

@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "service": "Markdown Extractor API",
        "status": "running",
        "version": "1.0.0",
        "model": "docling-q8_0 (258M parameters)"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    if converter is None:
        raise HTTPException(status_code=503, detail="Docling converter not initialized")
    
    return {
        "status": "healthy",
        "model": "docling-q8_0",
        "ready": True
    }

@app.post("/convert")
async def convert_to_markdown(file: UploadFile = File(...)):
    """
    Convert uploaded document to markdown
    
    Supported formats:
    - PDF (native and scanned)
    - DOCX, DOC
    - Images: PNG, JPG, JPEG, TIFF
    - TXT, HTML
    
    Returns:
    - JSON with markdown content and metadata
    """
    if converter is None:
        raise HTTPException(status_code=503, detail="Docling converter not initialized")
    
    try:
        # Validate file extension
        allowed_extensions = {'.pdf', '.docx', '.doc', '.png', '.jpg', '.jpeg', '.tiff', '.txt', '.html'}
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type: {file_ext}. Allowed: {', '.join(allowed_extensions)}"
            )
        
        logger.info(f"Processing file: {file.filename} ({file_ext})")
        
        # Save uploaded file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
        
        logger.info(f"Saved to temporary file: {tmp_path}")
        
        # Convert document to markdown using Docling
        logger.info("Starting Docling conversion...")
        result = converter.convert(tmp_path)
        markdown = result.document.export_to_markdown()
        
        logger.info(f"Conversion successful. Markdown length: {len(markdown)} chars")
        
        # Extract metadata if available
        metadata = {
            "pages": getattr(result.document, 'num_pages', None),
            "title": getattr(result.document, 'title', None),
        }
        
        # Cleanup temporary file
        os.unlink(tmp_path)
        logger.info(f"Cleaned up temporary file: {tmp_path}")
        
        return JSONResponse(content={
            "success": True,
            "filename": file.filename,
            "file_type": file_ext,
            "markdown": markdown,
            "metadata": metadata,
            "markdown_length": len(markdown)
        })
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Conversion failed: {str(e)}", exc_info=True)
        
        # Cleanup temporary file if it exists
        if 'tmp_path' in locals():
            try:
                os.unlink(tmp_path)
            except:
                pass
        
        raise HTTPException(status_code=500, detail=f"Conversion failed: {str(e)}")

@app.get("/supported-formats")
async def supported_formats():
    """List supported document formats"""
    return {
        "formats": [
            {"extension": ".pdf", "description": "PDF documents (native and scanned)"},
            {"extension": ".docx", "description": "Microsoft Word (2007+)"},
            {"extension": ".doc", "description": "Microsoft Word (legacy)"},
            {"extension": ".png", "description": "PNG images"},
            {"extension": ".jpg/.jpeg", "description": "JPEG images"},
            {"extension": ".tiff", "description": "TIFF images"},
            {"extension": ".txt", "description": "Plain text files"},
            {"extension": ".html", "description": "HTML documents"}
        ]
    }
EOF
```

---

## Step 6: Create Docker Compose Configuration

Create docker-compose.yml to orchestrate the service:

```bash
# Create docker-compose.yml in project root
cat > ~/markdown-extractor/docker-compose.yml << 'EOF'
version: '3.8'

services:
  markdown-extractor:
    build: .
    container_name: markdown-extractor
    ports:
      - "5000:5000"
    volumes:
      - ./models:/models:ro
      - ./api:/app:ro
    environment:
      - MODEL_PATH=/models/docling-q8_0.gguf
      - PYTHONUNBUFFERED=1
    deploy:
      resources:
        limits:
          memory: 3G
          cpus: '1.5'
        reservations:
          memory: 2G
          cpus: '1.0'
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  models:
EOF
```

---

## Step 7: Configure Firewall

Open port 5000 to allow external access to the API:

```bash
# Check if UFW is active
sudo ufw status

# If UFW is active, allow port 5000
sudo ufw allow 5000/tcp

# Verify the rule was added
sudo ufw status numbered
```

---

## Step 8: Build and Deploy the Service

Build the Docker image and start the service:

```bash
# Navigate to project directory
cd ~/markdown-extractor

# Build the Docker image (this will take a few minutes)
docker-compose build

# Start the service in detached mode
docker-compose up -d

# Verify the container is running
docker-compose ps

# Check container logs
docker-compose logs -f markdown-extractor
```

Expected output should show:
- Docling initialization messages
- "Application startup complete" message
- Uvicorn running on http://0.0.0.0:5000

---

## Step 9: Test the API Service

Test the API endpoints to verify deployment:

```bash
# Test root endpoint
curl http://localhost:5000/

# Test health check
curl http://localhost:5000/health

# Test supported formats endpoint
curl http://localhost:5000/supported-formats
```

Expected responses:
- Root: JSON with service info
- Health: `{"status":"healthy","model":"docling-q8_0","ready":true}`
- Formats: List of supported file formats

---

## Step 10: Test Document Conversion (Optional)

Test the conversion endpoint with a sample file:

```bash
# Create a simple test HTML file
cat > ~/test.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Test Document</title></head>
<body>
<h1>Test Heading</h1>
<p>This is a test paragraph.</p>
</body>
</html>
EOF

# Test conversion endpoint
curl -X POST http://localhost:5000/convert \
  -F "file=@/root/test.html" \
  -H "Content-Type: multipart/form-data" | jq .

# Clean up test file
rm ~/test.html
```

Expected response: JSON object with `success: true` and markdown content.

---

## Step 11: External Access Configuration

The API is now accessible from external machines at: `http://31.97.115.105:5000`

To test from a local development machine:

```bash
# Test from local machine (replace with actual VPS IP)
curl http://31.97.115.105:5000/health
```

---

## Step 12: Set Up Nginx Reverse Proxy (Optional)

If you want to access the API via a domain name instead of IP:port, configure Nginx:

```bash
# Create Nginx configuration for the API
sudo nano /etc/nginx/sites-available/markdown-extractor
```

Add the following configuration:

```nginx
server {
    listen 80;
    server_name markdown.your-domain.com;  # Replace with your domain

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeout for large file processing
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        
        # Increase max body size for file uploads
        client_max_body_size 50M;
    }
}
```

Enable the configuration:

```bash
# Create symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/markdown-extractor /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

## Step 13: Add SSL Certificate (Optional)

If using a domain, add SSL with Let's Encrypt:

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain and install certificate
sudo certbot --nginx -d markdown.your-domain.com

# Verify auto-renewal is configured
sudo certbot renew --dry-run
```

---

## Monitoring and Maintenance Commands

Useful commands for managing the service:

```bash
# View logs in real-time
docker-compose logs -f

# View logs for last 100 lines
docker-compose logs --tail=100

# Restart the service
docker-compose restart

# Stop the service
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild after code changes
docker-compose up -d --build

# Check resource usage
docker stats markdown-extractor

# Check disk usage
docker system df
```

---

## Local Development Integration

To use this API from your local development machine:

### Python Example:
```python
import requests

# API endpoint
api_url = "http://31.97.115.105:5000/convert"

# Upload a file
with open("document.pdf", "rb") as f:
    files = {"file": f}
    response = requests.post(api_url, files=files)
    
if response.status_code == 200:
    result = response.json()
    markdown = result["markdown"]
    print(markdown)
```

### JavaScript/Node.js Example:
```javascript
const FormData = require('form-data');
const fs = require('fs');
const fetch = require('node-fetch');

async function convertToMarkdown(filePath) {
    const formData = new FormData();
    formData.append('file', fs.createReadStream(filePath));
    
    const response = await fetch('http://31.97.115.105:5000/convert', {
        method: 'POST',
        body: formData
    });
    
    const result = await response.json();
    return result.markdown;
}
```

### cURL Example:
```bash
curl -X POST http://31.97.115.105:5000/convert \
  -F "file=@/path/to/document.pdf" \
  -H "Accept: application/json"
```

---

## Troubleshooting

### Issue: Container fails to start
```bash
# Check logs for errors
docker-compose logs markdown-extractor

# Check if port 5000 is already in use
sudo netstat -tulpn | grep 5000

# Rebuild the container
docker-compose down
docker-compose up -d --build
```

### Issue: Out of memory errors
```bash
# Check memory usage
free -h
docker stats

# Increase memory limit in docker-compose.yml
# Edit: memory: 4G (increase from 3G)

# Restart with new limits
docker-compose down
docker-compose up -d
```

### Issue: Slow conversion times
```bash
# Check CPU usage
htop

# Increase CPU allocation in docker-compose.yml
# Edit: cpus: '2.0' (increase from 1.5)

# Restart
docker-compose restart
```

### Issue: Firewall blocking access
```bash
# Check firewall status
sudo ufw status verbose

# Ensure port 5000 is allowed
sudo ufw allow 5000/tcp

# Reload firewall
sudo ufw reload
```

---

## Success Criteria

The deployment is successful when:

1. ✅ Docker container is running: `docker-compose ps` shows "Up" status
2. ✅ Health check passes: `curl http://localhost:5000/health` returns healthy status
3. ✅ API is accessible externally: `curl http://31.97.115.105:5000/` returns service info
4. ✅ Document conversion works: Test file successfully converts to markdown
5. ✅ Logs show no errors: `docker-compose logs` displays normal operation

---

## Next Steps After Successful Deployment

1. **Test with various document types** (PDF, DOCX, images) from local machine
2. **Build frontend application locally** that calls this API
3. **Monitor resource usage** to ensure VPS can handle the load
4. **Consider adding authentication** if exposing publicly
5. **Set up monitoring/alerting** for production use
6. **Deploy full application** to VPS once local development is complete

---

## Security Considerations

For production deployment, implement:

1. **API Authentication**: Add API key or JWT authentication
2. **Rate Limiting**: Prevent abuse with request rate limits  
3. **Input Validation**: Stricter file type and size validation
4. **HTTPS Only**: Enforce SSL/TLS for all connections
5. **CORS Configuration**: Restrict allowed origins to your domain only
6. **File Size Limits**: Configure maximum upload size
7. **Logging**: Implement comprehensive logging for security auditing

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│           VPS: 31.97.115.105 (KVM 2)           │
│         2 CPU cores, 8GB RAM, 100GB SSD        │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │   Docker Container: markdown-extractor  │   │
│  ├─────────────────────────────────────────┤   │
│  │                                         │   │
│  │  FastAPI Service (Port 5000)           │   │
│  │  ├─ Docling Converter                  │   │
│  │  ├─ Model: docling-q8_0.gguf (450MB)   │   │
│  │  └─ Endpoints:                         │   │
│  │     - GET  /                           │   │
│  │     - GET  /health                     │   │
│  │     - POST /convert                    │   │
│  │     - GET  /supported-formats          │   │
│  │                                         │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  Volumes:                                       │
│  - ./models → /models (read-only)              │
│  - ./api → /app (read-only)                    │
│                                                 │
└─────────────────────────────────────────────────┘
                        ↓
              Accessible via HTTP
                        ↓
        http://31.97.115.105:5000/convert
                        ↓
┌─────────────────────────────────────────────────┐
│        Local Development Machine                │
│  (Build frontend, test API integration)         │
└─────────────────────────────────────────────────┘
```

---

## Resource Allocation

**VPS Resources (KVM 2):**
- Total RAM: 8GB
- Total CPU: 2 cores
- Total Storage: 100GB

**Markdown Extractor Service:**
- RAM Limit: 3GB (reserved: 2GB)
- CPU Limit: 1.5 cores (reserved: 1.0)
- Storage: ~2GB (model + Docker layers)

**Remaining Resources:**
- Available RAM: ~5GB (for OS, existing apps, buffers)
- Available CPU: 0.5 cores (for OS, existing apps)
- Available Storage: ~98GB (plenty for documents, logs)

---

## API Endpoints Reference

### GET /
Returns basic service information.

**Response:**
```json
{
  "service": "Markdown Extractor API",
  "status": "running",
  "version": "1.0.0",
  "model": "docling-q8_0 (258M parameters)"
}
```

### GET /health
Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "healthy",
  "model": "docling-q8_0",
  "ready": true
}
```

### POST /convert
Convert uploaded document to markdown.

**Request:**
- Method: POST
- Content-Type: multipart/form-data
- Body: file (binary)

**Response:**
```json
{
  "success": true,
  "filename": "document.pdf",
  "file_type": ".pdf",
  "markdown": "# Document Title\n\nContent...",
  "metadata": {
    "pages": 5,
    "title": "Document Title"
  },
  "markdown_length": 1234
}
```

### GET /supported-formats
List all supported document formats.

**Response:**
```json
{
  "formats": [
    {"extension": ".pdf", "description": "PDF documents (native and scanned)"},
    {"extension": ".docx", "description": "Microsoft Word (2007+)"},
    ...
  ]
}
```

---

## End of Guide

This deployment guide provides complete instructions for setting up the Markdown Extractor API service. Follow the steps in order for a successful deployment. For issues or questions, refer to the Troubleshooting section or check the container logs for detailed error messages.