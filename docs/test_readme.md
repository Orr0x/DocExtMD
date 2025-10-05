# Test Scripts for Markdown Extractor API

This directory contains test scripts to help you test the Markdown Extractor API with your test files.

## 📁 Test Files Structure

Your `Test Files` folder contains:
- **FedEx Contract.pdf** - PDF document for testing
- **FedEx Contract.pdf.docx** - Word document for testing
- **FedEx Contract.pdf.txt** - Text file for testing
- **RightFit Interiors — Bespoke Carpentry & Joinery.html** - HTML file for testing
- **Screenshot 2025-10-05 012248.png** - PNG image for testing

## 🚀 Test Scripts

### 1. Bash Script (`test_api.sh`)
**For Linux/Mac users or Windows with Git Bash/WLS**

```bash
# Make executable (Linux/Mac)
chmod +x test_api.sh

# Run tests
./test_api.sh
```

### 2. Python Script (`test_api.py`)
**Cross-platform Python script**

```bash
# Activate virtual environment (if not already activated)
# Windows PowerShell:
.venv\Scripts\Activate.ps1

# Linux/Mac:
# source .venv/bin/activate

# Run tests (virtual environment should already have requests installed)
python test_api.py
```

### 3. PowerShell Script (`test_api.ps1`)
**For Windows PowerShell users**

```powershell
# Run tests (from the project root)
.\test_api.ps1

# Or specify custom API URL
.\test_api.ps1 -ApiUrl "http://your-server:5000"
```

## ✅ What the Scripts Test

1. **Health Check** - Verifies API is running
2. **Supported Formats** - Lists all supported file types
3. **PDF Conversion** - Tests PDF document conversion
4. **HTML Conversion** - Tests HTML file conversion
5. **Image Conversion** - Tests PNG image conversion
6. **DOCX Conversion** - Tests Word document (if available)
7. **TXT Conversion** - Tests plain text (if available)
8. **Error Handling** - Tests rejection of unsupported file types

## 📊 Expected Output

Each script will show:
- ✅ **Success indicators** for working conversions
- 📊 **File size and metadata** for converted files
- ❌ **Error messages** for failed conversions
- 🎨 **Colored output** for easy reading

## 🔧 Troubleshooting

**If scripts can't find test files:**
- Ensure you're running from the project root directory
- Check that the `Test Files` folder exists and contains files
- Verify file paths in the scripts match your folder structure

**If API connection fails:**
- Make sure the Docker container is running: `docker-compose ps`
- Check the API is accessible: `curl http://localhost:5000/health`
- Verify the API URL in the scripts matches your setup

**For Windows users:**
- Use PowerShell script for best compatibility
- Or use Python script which works cross-platform

## 🎯 File Path Handling

**Answer to your question:** You do NOT need to move files to the root directory!

The scripts are designed to work with files in the `Test Files` folder by using relative paths:
- `Test Files/FedEx Contract.pdf`
- `Test Files/RightFit Interiors — Bespoke Carpentry & Joinery.html`
- etc.

This approach keeps your project organized while allowing easy testing.

## 🚀 Quick Start

1. **Ensure your API is running:**
   ```bash
   docker-compose up -d
   curl http://localhost:5000/health
   ```

2. **Run a quick test:**
   ```bash
   # Python (recommended)
   python test_api.py

   # Or PowerShell (Windows)
   .\test_api.ps1

   # Or Bash (Linux/Mac)
   ./test_api.sh
   ```

3. **Check the results** - you should see successful conversions for PDF, HTML, and PNG files!

## 📈 Performance Testing

The scripts also show:
- **File sizes** before conversion
- **Processing times** (implied by response times)
- **Output markdown length**
- **Document metadata** (pages, titles, etc.)

This helps you understand the API's performance characteristics with different file types.

## 🔍 Individual File Testing

You can also test individual files manually:

```bash
# Test specific PDF
curl -X POST http://localhost:5000/convert \
  -F "file=@Test Files/FedEx Contract.pdf"

# Test specific HTML
curl -X POST http://localhost:5000/convert \
  -F "file=@Test Files/RightFit Interiors — Bespoke Carpentry & Joinery.html"
```

The test scripts provide a comprehensive way to validate your API with multiple file types while keeping everything organized in your `Test Files` folder!
