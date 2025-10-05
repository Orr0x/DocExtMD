# Markdown Extractor API

A Docker-based API service that converts documents to Markdown using Docling. Supports PDF, DOCX, images, HTML, and text files.

## Features

- **Multiple Format Support**: PDF (native and scanned), DOCX, DOC, PNG, JPG, JPEG, TIFF, TXT, HTML
- **High-Quality Conversion**: Uses Docling's advanced document understanding
- **RESTful API**: Simple HTTP endpoints for easy integration
- **Docker Deployment**: Easy deployment with Docker Compose
- **Health Monitoring**: Built-in health checks and logging
- **CORS Support**: Ready for web application integration

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available (8GB recommended for production)

### 🚀 Live API

**The Docling API is now live and accessible at:**
```
http://31.97.115.105:5000
```

**Test the API:**
```bash
# Health check
curl http://31.97.115.105:5000/health

# API information
curl http://31.97.115.105:5000/

# Convert a document
curl -X POST http://31.97.115.105:5000/convert \
  -F "file=@/path/to/document.pdf" \
  -H "Accept: application/json"
```

### 1. Clone or Download

```bash
# If using git
git clone https://github.com/Orr0x/DocExtMD.git
cd DocExtMD

# Or download the project files
```

### 2. Build and Run

```bash
# Build the Docker image
docker-compose build

# Start the service
docker-compose up -d

# Check status
docker-compose ps
```

### 3. Verify Deployment

```bash
# Health check
curl http://localhost:5000/health

# API info
curl http://localhost:5000/

# Supported formats
curl http://localhost:5000/supported-formats
```

## API Endpoints

### GET /
Returns basic service information.

**Response:**
```json
{
  "service": "Markdown Extractor API",
  "status": "running",
  "version": "1.0.0",
  "model": "docling-q4_0 (198M parameters)"
}
```

### GET /health
Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "healthy",
  "model": "docling-q4_0",
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
    {"extension": ".doc", "description": "Microsoft Word (legacy)"},
    {"extension": ".png", "description": "PNG images"},
    {"extension": ".jpg/.jpeg", "description": "JPEG images"},
    {"extension": ".tiff", "description": "TIFF images"},
    {"extension": ".txt", "description": "Plain text files"},
    {"extension": ".html", "description": "HTML documents"}
  ]
}
```

## Usage Examples

### Python

```python
import requests

# API endpoint (update with your server URL)
api_url = "http://localhost:5000/convert"

# Upload a file
with open("document.pdf", "rb") as f:
    files = {"file": f}
    response = requests.post(api_url, files=files)

if response.status_code == 200:
    result = response.json()
    markdown = result["markdown"]
    print(markdown)
else:
    print(f"Error: {response.status_code}")
```

### JavaScript/Node.js

```javascript
const FormData = require('form-data');
const fs = require('fs');
const fetch = require('node-fetch');

async function convertToMarkdown(filePath) {
    const formData = new FormData();
    formData.append('file', fs.createReadStream(filePath));

    const response = await fetch('http://localhost:5000/convert', {
        method: 'POST',
        body: formData
    });

    const result = await response.json();
    return result.markdown;
}

// Usage
convertToMarkdown('./document.pdf').then(markdown => {
    console.log(markdown);
});
```

### cURL

```bash
# Upload a PDF file
curl -X POST http://localhost:5000/convert \
  -F "file=@/path/to/document.pdf" \
  -H "Accept: application/json"

# Upload an image
curl -X POST http://localhost:5000/convert \
  -F "file=@/path/to/image.png" \
  -H "Accept: application/json"
```

## Docker Commands

### Development

```bash
# View logs in real-time
docker-compose logs -f

# View logs for last 100 lines
docker-compose logs --tail=100

# Restart the service
docker-compose restart

# Rebuild after code changes
docker-compose up -d --build
```

### Monitoring

```bash
# Check resource usage
docker stats markdown-extractor

# Check disk usage
docker system df

# Container health
docker inspect markdown-extractor | grep -A 5 "Health"
```

### Troubleshooting

```bash
# Check logs for errors
docker-compose logs markdown-extractor

# Stop the service
docker-compose down

# Stop and remove volumes (removes model data)
docker-compose down -v

# Clean rebuild
docker-compose down -v && docker-compose up -d --build
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_PATH` | `/models/docling-q4_0.gguf` | Path to Docling model file |

### Model Options

**Current Model (Q4_0):**
- **File**: `docling-q4_0.gguf`
- **Size**: 198MB
- **Parameters**: ~258M
- **Performance**: Good balance of speed and quality
- **Memory Usage**: ~2-3GB RAM

**Alternative Model (Q8_0) - For Future Reference:**
- **File**: `docling-q8_0.gguf`
- **Size**: 396MB
- **Parameters**: ~258M (higher precision)
- **Performance**: Higher quality, slower processing
- **Memory Usage**: ~4-5GB RAM
- **Usage**: Change `MODEL_PATH` to `/models/docling-q8_0.gguf` in docker-compose.yml

### Docker Compose Settings

- **Port**: 5000 (configurable in docker-compose.yml)
- **Memory Limit**: 3GB
- **CPU Limit**: 1.5 cores
- **Volumes**:
  - `./models:/models:ro` - Model files (read-only)
  - `./api:/app:ro` - API code (read-only)

## Supported File Types

| Extension | Description | Notes |
|-----------|-------------|-------|
| `.pdf` | PDF documents | Native and scanned PDFs |
| `.docx` | Microsoft Word | 2007+ format |
| `.doc` | Microsoft Word | Legacy format |
| `.png` | PNG images | Standard image format |
| `.jpg`, `.jpeg` | JPEG images | Common image format |
| `.tiff` | TIFF images | High-quality image format |
| `.txt` | Plain text | Simple text files |
| `.html` | HTML documents | Web pages |

## Performance

### System Requirements
- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Storage**: ~2GB for model + Docker layers

### Processing Speed
- **Small files** (< 1MB): 2-5 seconds
- **Medium files** (1-10MB): 5-15 seconds
- **Large files** (> 10MB): 15-60 seconds

*Performance varies based on file complexity and system resources.*

## Troubleshooting

### Common Issues

**Container fails to start:**
```bash
# Check logs
docker-compose logs markdown-extractor

# Verify port availability
docker-compose port markdown-extractor

# Check if model file exists
docker run --rm -v $(pwd)/models:/models alpine ls -la /models/
```

**Out of memory errors:**
```bash
# Check memory usage
docker stats

# Reduce memory limit in docker-compose.yml
# Edit: memory: 2G (from 3G)
```

**Slow conversion:**
```bash
# Check CPU usage
htop

# Increase CPU allocation in docker-compose.yml
# Edit: cpus: '2.0' (from 1.5)
```

**File upload errors:**
```bash
# Check file permissions
ls -la /path/to/file

# Verify file format
file /path/to/file

# Test with smaller file first
```

## Production Deployment

### Security Considerations

1. **Configure CORS**: Update allowed origins in `api/main.py`
2. **Add Authentication**: Implement API key or JWT authentication
3. **Rate Limiting**: Add request rate limits
4. **HTTPS**: Use reverse proxy with SSL (nginx example in deployment guide)
5. **File Size Limits**: Configure maximum upload size
6. **Logging**: Implement comprehensive logging for security auditing

### Scaling

For high-traffic scenarios:
1. Use a load balancer
2. Deploy multiple instances
3. Consider using a more powerful model
4. Implement caching for frequently processed documents

## Architecture

```
┌─────────────────────────────────────────────────┐
│                Docker Host                      │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │   Docker Container: markdown-extractor  │   │
│  ├─────────────────────────────────────────┤   │
│  │                                         │   │
│  │  FastAPI Service (Port 5000)           │   │
│  │  ├─ Docling Converter                  │   │
│  │  ├─ Model: docling-q4_0.gguf (198MB)   │   │
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
        http://localhost:5000/convert
```

## 📚 Documentation Structure

This `docs/` folder contains all project documentation:

### **📖 Guides & Documentation**
- **`README.md`** - This main documentation file
- **`Markdown Extractor - Docling Mode.md`** - Complete deployment guide
- **`deploy_to_hostinger_vps.md`** - Hostinger VPS deployment guide
- **`PROJECT_CONTEXT.md`** - Current project status and deployment info
- **`lm_studio_usage_guide.md`** - Complete LM Studio integration guide
- **`lm_studio_troubleshooting.md`** - Common issues and solutions
- **`docling_official_resources.md`** - Official Docling project information
- **`model_comparison.md`** - Model version comparisons

### **🧪 Testing & Scripts**
Test scripts are located in the `../scripts/` folder:
- `test_pdf_extraction.py` - Python PDF extraction test script
- `test_pdf_extraction.ps1` - PowerShell PDF extraction test script
- `run_test.bat` - Easy batch file to run tests
- `test_api.py` - Python API testing script
- `extract_markdown.py` - Batch markdown extraction script
- `deploy.sh` - Automated deployment script
- `vps_manage.sh` - VPS management script
- `vps_setup.sh` - VPS setup script

### **📊 Project Structure**
```
📦 DocExtMD/
├── 📁 docs/                    # Documentation (this folder)
│   ├── README.md              # Main documentation
│   ├── lm_studio_usage_guide.md
│   ├── lm_studio_troubleshooting.md
│   ├── model_comparison.md
│   └── extraction.log
├── 📁 scripts/                 # Test and utility scripts
├── 📁 api/                     # Core application code
├── 📁 models/                  # Model files
├── 📁 Test Files/              # Test data
├── 📁 Output/                  # Generated markdown files
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

## 🔗 Quick Links

- **🏠 Main Documentation**: This file
- **🧪 Testing Guide**: `../scripts/test_readme.md`
- **🔧 LM Studio Setup**: `lm_studio_usage_guide.md`
- **🐛 Troubleshooting**: `lm_studio_troubleshooting.md`

## License

This project is provided as-is for educational and development purposes.

## 🎉 Deployment Status

**✅ Successfully Deployed to Hostinger VPS**
- **API URL**: http://31.97.115.105:5000
- **Status**: Live and operational
- **Model**: docling-q8_0.gguf (396MB, high quality)
- **Test Results**: PDF extraction working correctly
- **Firewall**: Port 5000 properly configured

**Test the live API:**
```bash
# Quick health check
curl http://31.97.115.105:5000/health

# Run the test script
cd scripts
python test_pdf_extraction.py
```

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review container logs: `docker-compose logs`
3. Verify system requirements and file formats
4. Test with sample files before production use
5. Check the `../scripts/` folder for testing utilities
6. For VPS management: SSH into your VPS and use `docker-compose` commands
