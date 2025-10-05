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
model_path = os.getenv("MODEL_PATH", "/models/docling-q4_0.gguf")
logger.info(f"Initializing Docling with model: {model_path}")

try:
    # Initialize Docling converter with default settings
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

        # Debug logging
        logger.info(f"File: {file.filename}, Extension: '{file_ext}', Allowed: {allowed_extensions}")

        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type: {file_ext}. Allowed: {', '.join(sorted(allowed_extensions))}"
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

        # Try multiple approaches to get clean markdown
        try:
            # Method 1: Standard markdown export
            markdown = result.document.export_to_markdown()
        except Exception as e1:
            logger.warning(f"Standard markdown export failed: {e1}")
            try:
                # Method 2: Try with different export options
                markdown = result.document.export_to_markdown(
                    image_mode="placeholder",  # Use placeholders instead of embedding images
                    table_mode="markdown"      # Ensure tables are in markdown format
                )
            except Exception as e2:
                logger.warning(f"Alternative markdown export failed: {e2}")
                # Method 3: Fallback to basic text extraction
                markdown = ""
                for item in result.document.body.body:
                    if hasattr(item, 'text') and item.text:
                        markdown += item.text + "\n\n"

        logger.info(f"Conversion successful. Markdown length: {len(markdown)} chars")

        # Extract metadata if available (ensuring JSON serializable)
        metadata = {}
        try:
            # Only extract basic attributes that are JSON serializable
            if hasattr(result.document, 'num_pages') and result.document.num_pages is not None:
                metadata["pages"] = int(result.document.num_pages)
            if hasattr(result.document, 'title') and result.document.title is not None:
                metadata["title"] = str(result.document.title)
        except Exception as e:
            logger.warning(f"Could not extract metadata: {e}")
            metadata = {"pages": None, "title": None}

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
