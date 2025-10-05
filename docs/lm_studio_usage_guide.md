# LM Studio Usage Guide - Docling Model

Great news! Your `granite-docling-258m` model (which is the `docling-q4_0.gguf` file) is successfully loading in LM Studio! 🎉

## ✅ What's Working

- **Model**: `docling-q4_0.gguf` (198MB Q4 quantization)
- **LM Studio Compatible**: ✅ Loading successfully
- **Size**: 198MB (perfect for local inference)
- **Quality**: Good balance of size and performance

## 🚀 How to Use in LM Studio

### 1. Model Loading
- **File**: `models/docling-q4_0.gguf`
- **Name in LM Studio**: Shows as `granite-docling-258m` (this is normal)
- **Parameters**: 258M parameters
- **Context Size**: Typically 4096-8192 tokens

### 2. Recommended Settings for Document Processing

**For Best Results:**
- **Temperature**: 0.1-0.3 (low for consistent document analysis)
- **Top P**: 0.9 (good balance)
- **Max Tokens**: 2048-4096 (depending on document length)
- **Context Window**: 4096+ tokens

**GPU Settings (if available):**
- Enable GPU acceleration in LM Studio settings
- Use appropriate GPU layers for your VRAM

### 3. Prompt Engineering for Document Tasks

**For Document Analysis:**
```
Analyze the following document and extract key information:

[DOCUMENT CONTENT]

Please provide:
1. Main topic/subject
2. Key points and findings
3. Important dates or deadlines
4. Action items or next steps
```

**For Markdown Conversion:**
```
Convert the following document content to clean, structured markdown:

[DOCUMENT CONTENT]

Focus on:
- Proper heading hierarchy
- Clear formatting
- Preserving important structure
```

**For Q&A about Documents:**
```
Context: [DOCUMENT CONTENT]

Question: [YOUR QUESTION]

Provide a detailed answer based on the document content.
```

## 📊 Performance Tips

### Memory Usage
- **Model Size**: 198MB on disk
- **RAM Usage**: ~400-600MB when loaded
- **VRAM Usage**: ~300-500MB (GPU)

### Speed Optimization
- Use higher quantization if speed is critical (but quality may suffer)
- Increase context size for longer documents
- Use GPU acceleration when available

## 🔧 Troubleshooting LM Studio Issues

**If model fails to load:**
1. Check file path in LM Studio settings
2. Ensure enough RAM/VRAM is available
3. Try restarting LM Studio
4. Verify model file isn't corrupted

**If inference is slow:**
1. Enable GPU acceleration
2. Reduce context window size
3. Close other applications
4. Consider Q3 or lower quantization

**If getting poor results:**
1. Adjust temperature (try 0.1-0.3)
2. Increase context window
3. Refine your prompts
4. Try the Q5 model for better quality

## 🎯 Next Steps

1. **Test Document Processing**: Try uploading a PDF or document through your API and see how the model performs
2. **Tune Settings**: Experiment with different temperature and context settings
3. **Compare Models**: If needed, try the Q5 model for higher quality vs the Q4 for speed
4. **Monitor Performance**: Keep track of processing speed and output quality

## 📈 Alternative Models Available

You also have these options in your `models/` directory:

- **docling-q8_0.gguf** (396MB) - Highest quality, largest size
- **docling-q4_0.gguf** (198MB) - Currently using (good balance)
- **Other quantizations** available for download if needed

The Q4 model you're using now should provide excellent performance for document analysis tasks while being efficient for local inference in LM Studio!

## 🛠️ Integration with Your API

Since your API is running in Docker, you can:

1. **Test locally**: Use curl/PowerShell scripts to test document conversion
2. **Monitor logs**: Check `docker-compose logs` for API performance
3. **Scale as needed**: The current setup should handle moderate document processing loads

Let me know if you need help with specific prompts, settings adjustments, or if you want to try other model quantizations!
