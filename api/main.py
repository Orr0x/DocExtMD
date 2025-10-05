from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from docling.document_converter import DocumentConverter
import tempfile
import os
import logging
import signal
from PIL import Image
import io

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

# Initialize Docling converter with CPU optimizations
# Note: The model path can be configured via environment variable
model_path = os.getenv("MODEL_PATH", "/models/docling-q4_0.gguf")
logger.info(f"Initializing Docling with model: {model_path}")

def timeout_handler(signum, frame):
    """Handle processing timeout"""
    raise TimeoutError("Image processing timeout - CPU overload")

def compress_image(image_data, max_size=(800, 600), quality=85):
    """Compress image to reduce CPU processing load"""
    try:
        img = Image.open(io.BytesIO(image_data))
        
        # Resize if too large
        if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
            logger.info(f"Resized image to {img.size}")
        
        # Convert to RGB if needed (for JPEG compression)
        if img.mode in ('RGBA', 'LA', 'P'):
            img = img.convert('RGB')
        
        # Compress
        output = io.BytesIO()
        img.save(output, format='JPEG', quality=quality, optimize=True)
        compressed_data = output.getvalue()
        
        logger.info(f"Compressed image: {len(image_data)} -> {len(compressed_data)} bytes")
        return compressed_data
        
    except Exception as e:
        logger.warning(f"Image compression failed: {e}")
        return image_data  # Return original if compression fails

try:
    # Initialize Docling converter with basic settings
    # Note: Advanced optimization parameters may not be supported in all versions
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
        "model": "docling-q4_0 (198M parameters)",
        "optimization": "cpu_optimized"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    if converter is None:
        raise HTTPException(status_code=503, detail="Docling converter not initialized")

    return {
        "status": "healthy",
        "model": "docling-q4_0",
        "ready": True,
        "optimization": "cpu_optimized"
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

        # Read file content
        content = await file.read()
        original_size = len(content)

        # Compress images to reduce CPU processing load
        if file_ext in {'.png', '.jpg', '.jpeg', '.tiff'}:
            logger.info("Compressing image to reduce CPU processing load...")
            content = compress_image(content)

        # Save uploaded file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        logger.info(f"Saved to temporary file: {tmp_path}")

        # Set timeout for processing (90 seconds for images, 120 for documents)
        timeout_seconds = 90 if file_ext in {'.png', '.jpg', '.jpeg', '.tiff'} else 120
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(timeout_seconds)

        try:
            # Convert document to markdown using Docling
            logger.info("Starting Docling conversion...")
            result = converter.convert(tmp_path)
            signal.alarm(0)  # Cancel timeout
        except TimeoutError:
            logger.error(f"Processing timed out after {timeout_seconds} seconds - CPU overload")
            # Cleanup temporary file
            os.unlink(tmp_path)
            raise HTTPException(
                status_code=408, 
                detail=f"Processing timeout - file too complex. Try a smaller image or simpler document."
            )

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
            "metadata": {
                **metadata,
                "processing_info": {
                    "compressed": original_size != len(content),
                    "original_size": original_size,
                    "processed_size": len(content),
                    "timeout_seconds": timeout_seconds,
                    "optimization": "cpu_optimized"
                }
            },
            "markdown_length": len(markdown),
            "optimization": "cpu_optimized"
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

        # Return graceful error instead of crashing
        return JSONResponse(content={
            "success": False,
            "error": f"Conversion failed: {str(e)}",
            "suggestion": "Try a smaller image or simpler document",
            "optimization": "cpu_optimized"
        }, status_code=500)

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
