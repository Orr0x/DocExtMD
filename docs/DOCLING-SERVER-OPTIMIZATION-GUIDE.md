# Docling Server CPU Optimization Guide

## 🚨 Problem Context

The current Docling server is **crashing during image processing** due to CPU exhaustion. The server processes images successfully until it reaches the OCR/text extraction phase, then the process dies completely.

### Error Pattern:
```
2025-10-05 19:15:18,984 - INFO - Starting Docling conversion...
2025-10-05 19:15:19,133 - INFO - Initializing pipeline for StandardPdfPipeline
2025-10-05 19:15:22,959 - INFO - Processing document tmp0c29fd3m.png
[PROCESS DIES HERE - NO MORE LOGS]
```

### Client Error:
```
TypeError: fetch failed
[cause]: [Error [SocketError]: other side closed]
bytesWritten: 236230, bytesRead: 0
```

## 🎯 Root Cause Analysis

- **CPU Exhaustion**: Image OCR processing is extremely CPU-intensive
- **Model Size**: q8_0 model (8GB) is too heavy for the server resources
- **No Timeout Protection**: Process hangs indefinitely until system kills it
- **No Error Handling**: Server crashes instead of returning graceful errors

## 🛠️ Required Optimizations

### 1. **Reduce Model Size (CRITICAL)**
```python
# Change from q8 to q4 model
model_path = os.getenv("MODEL_PATH", "/models/docling-q4_0.gguf")

# Update health check response
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model": "docling-q4_0",  # Update from q8_0
        "ready": True
    }
```

**Benefits:**
- 50% smaller memory footprint (4GB vs 8GB)
- Significantly faster processing
- Less CPU intensive
- Still good accuracy for most documents

### 2. **CPU-Optimized Converter Settings**
```python
converter = DocumentConverter(
    # Use faster, less CPU-intensive OCR engine
    ocr_engine="tesseract",  # Faster than easyocr/rapidocr
    
    # Reduce image processing quality to save CPU
    image_resolution=150,    # Lower DPI = less CPU processing
    
    # Limit concurrent processing
    max_workers=1,           # Process one document at a time
    
    # CPU optimization settings
    cpu_threads=2,           # Limit CPU threads (adjust based on server)
    
    # Skip complex image analysis for faster processing
    skip_complex_analysis=True,
)
```

### 3. **Image Compression (Pre-processing)**
```python
from PIL import Image
import io

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

# Use in convert endpoint:
if file_ext in {'.png', '.jpg', '.jpeg', '.tiff'}:
    logger.info("Compressing image to reduce CPU processing load...")
    content = compress_image(content)
```

### 4. **Timeout Protection**
```python
import signal

def timeout_handler(signum, frame):
    """Handle processing timeout"""
    raise TimeoutError("Image processing timeout - CPU overload")

# In convert endpoint:
# Set timeout for processing (30 seconds for images, 60 for documents)
timeout_seconds = 30 if file_ext in {'.png', '.jpg', '.jpeg', '.tiff'} else 60
signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(timeout_seconds)

try:
    result = converter.convert(tmp_path)
    signal.alarm(0)  # Cancel timeout
except TimeoutError:
    logger.error(f"Processing timed out after {timeout_seconds} seconds - CPU overload")
    raise HTTPException(
        status_code=408, 
        detail=f"Processing timeout - file too complex. Try a smaller image or simpler document."
    )
```

### 5. **Enhanced Error Handling**
```python
try:
    result = converter.convert(tmp_path)
except Exception as e:
    logger.error(f"Docling conversion failed: {e}")
    # Return graceful error instead of crashing
    return JSONResponse(content={
        "success": False,
        "error": f"Conversion failed: {str(e)}",
        "suggestion": "Try a smaller image or simpler document"
    })
```

### 6. **Response Format Updates**
```python
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
```

## 📋 Implementation Checklist

- [ ] **Download q4_0 model** (replace q8_0)
- [ ] **Update model path** in environment/config
- [ ] **Add CPU-optimized converter settings**
- [ ] **Implement image compression**
- [ ] **Add timeout protection**
- [ ] **Enhance error handling**
- [ ] **Update health check response**
- [ ] **Test with small images first**
- [ ] **Monitor CPU usage during processing**

## 🧪 Testing Strategy

1. **Start with small images** (< 50KB)
2. **Monitor CPU usage** with `htop` during processing
3. **Test timeout handling** with large images
4. **Verify graceful error responses**
5. **Check memory usage** with `free -h`

## 🎯 Expected Results

After implementing these optimizations:

- ✅ **No more server crashes** during image processing
- ✅ **Faster processing times** (q4 model + optimizations)
- ✅ **Graceful error handling** instead of crashes
- ✅ **Better resource management** (CPU + memory)
- ✅ **Timeout protection** for problematic files

## 📞 Support

If you encounter issues during implementation:

1. **Check server resources**: `htop`, `free -h`
2. **Monitor logs**: Look for timeout/error messages
3. **Test incrementally**: Start with small files
4. **Verify model path**: Ensure q4_0 model is accessible

---

**Priority: HIGH** - Current server is unstable and crashes on image processing
