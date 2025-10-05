# Markdown Extractor API - Project Context

## Project Overview
This is a FastAPI-based document-to-markdown conversion service using Docling models. The project converts various document formats (PDF, DOCX, images, etc.) into clean markdown output.

## Key Components

### Core API (`api/main.py`)
- FastAPI application with document upload endpoint
- Uses Docling for document conversion
- Configured to use `docling-q4_0.gguf` model (198MB, works in LM Studio)
- Handles multiple file formats: PDF, DOCX, DOC, PNG, JPG, TIFF, TXT, HTML
- Returns markdown with metadata (pages, title)
- Includes fallback mechanisms for markdown export

### Docker Setup
- `Dockerfile`: Python 3.11-slim base with FastAPI, uvicorn, docling
- `docker-compose.yml`: Service orchestration with resource limits (3GB RAM, 1.5 CPU)
- Health checks and restart policies configured
- Models mounted as read-only volume

### Project Structure
```
I:\DocX\                    # Local project directory
├── api/                    # FastAPI application
├── docs/                   # Documentation and guides
├── scripts/                # Utility and test scripts
├── models/                 # Model files (ignored by Git)
├── Test Files/             # Test documents (ignored by Git)
├── deploy.sh              # Automated deployment script
├── vps_setup.sh           # VPS setup script
├── vps_manage.sh          # VPS management script
└── deploy_to_hostinger_vps.md  # Deployment guide
```

## Model Configuration
- **Primary Model**: `docling-q4_0.gguf` (198MB)
- **Location**: `/models/docling-q4_0.gguf` in container
- **Why Q4**: Q8 model (396MB) failed to load in LM Studio
- **Download**: Use `scripts/download_alternative_models.py`
- **Alternative**: `docling-q8_0.gguf` (396MB) for higher quality processing

## API Endpoints
- `GET /health` - Health check
- `GET /supported-formats` - List supported file types
- `POST /convert` - Convert document to markdown

## Deployment
- **Target**: Hostinger VPS
- **Automation**: `deploy.sh` handles SSH, Docker setup, file upload
- **Management**: `vps_manage.sh` provides service management interface
- **Firewall**: UFW configured for port 5000

## Recent Issues Resolved
1. **Model Loading**: Switched from Q8 to Q4 model for LM Studio compatibility
2. **JSON Serialization**: Fixed metadata extraction to ensure JSON serializable output
3. **File Extension Detection**: Improved validation and error handling
4. **Repository Size**: Removed large model files from Git tracking
5. **Project Organization**: Moved docs to `docs/` and scripts to `scripts/`

## Git Configuration
- **Repository**: https://github.com/Orr0x/DocExtMD.git
- **Local Directory**: I:\DocX
- **Branch**: main
- **Ignored Files**: models/, Test Files/, *.gguf, .venv/, logs/, Output/
- **Clean History**: Fresh repository without large file history

## Development Environment
- **Python**: 3.11 with virtual environment
- **Dependencies**: FastAPI, uvicorn, docling, python-multipart
- **Testing**: Scripts in `scripts/` for API testing and batch processing
- **Local Testing**: Docker Compose for containerized testing

## Key Files
- `api/main.py` - Main FastAPI application
- `docker-compose.yml` - Container orchestration
- `deploy.sh` - Automated deployment to VPS
- `vps_manage.sh` - Service management interface
- `docs/README.md` - Comprehensive documentation
- `scripts/extract_markdown.py` - Batch processing script

## Next Steps
1. ✅ Complete initial push to new repository
2. Test API functionality with Docker Compose
3. Deploy to Hostinger VPS using deployment scripts
4. Set up model download automation for VPS deployment
5. Update documentation with current project structure

## Notes
- Model files are excluded from Git and should be downloaded separately
- Test files are also excluded to keep repository lightweight
- All deployment scripts are configured for Hostinger VPS environment
- API includes comprehensive error handling and logging
