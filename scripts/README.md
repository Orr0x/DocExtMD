# 🧪 Test Scripts

This folder contains scripts for testing and validating the Markdown Extractor API.

## 📁 Available Scripts

### **Core Testing Scripts**

#### **`test_api.py`** - Python API Testing
- **Platform**: Cross-platform (Python)
- **Purpose**: Comprehensive API endpoint testing
- **Features**:
  - Health check and endpoint validation
  - File conversion testing
  - Error handling verification
  - Detailed logging and reporting

#### **`extract_markdown.py`** - Batch Extraction
- **Platform**: Cross-platform (Python)
- **Purpose**: Process all test files and generate markdown
- **Features**:
  - Batch processing of all supported file types
  - Output to `../Output/` folder
  - Progress tracking and error reporting
  - Comprehensive logging

### **Platform-Specific Scripts**

#### **`test_api.ps1`** - PowerShell Testing
- **Platform**: Windows PowerShell
- **Purpose**: Windows-specific API testing
- **Features**: PowerShell-native file handling and error management

#### **`test_api.sh`** - Bash Testing
- **Platform**: Linux/Mac
- **Purpose**: Unix-based API testing
- **Features**: Shell-native file operations

#### **`download_alternative_models.py`** - Model Management
- **Platform**: Cross-platform (Python)
- **Purpose**: Download alternative Docling models
- **Features**: Interactive model selection and download

## 🚀 Usage Instructions

### **Quick Start (Python - Recommended)**

```bash
# 1. Activate virtual environment (if using one)
.venv\Scripts\Activate.ps1  # Windows
# source .venv/bin/activate   # Linux/Mac

# 2. Run comprehensive tests
python test_api.py

# 3. Extract all test files to markdown
python extract_markdown.py
```

### **PowerShell (Windows Only)**
```powershell
# Run API tests
.\test_api.ps1

# Extract all files
# (Requires Python - use python extract_markdown.py)
```

### **Bash (Linux/Mac)**
```bash
# Make executable and run
chmod +x test_api.sh
./test_api.sh
```

## 📊 What Gets Tested

### **API Endpoints**
- ✅ **Health Check** (`GET /health`)
- ✅ **Service Info** (`GET /`)
- ✅ **Supported Formats** (`GET /supported-formats`)
- ✅ **File Conversion** (`POST /convert`)

### **File Types**
- 📄 **PDF Documents** (FedEx Contract.pdf)
- 📝 **DOCX Files** (FedEx Contract.pdf.docx)
- 🌐 **HTML Pages** (RightFit Interiors files)
- 🖼️ **PNG Images** (Screenshot files)
- 📄 **Text Files** (FedEx Contract.pdf.txt)

### **Test Scenarios**
- ✅ **Successful conversions**
- ❌ **Error handling** (unsupported files)
- 📊 **Performance metrics**
- 🔍 **Content validation**

## 📁 File Organization

### **Input Files**
- **Location**: `../Test Files/`
- **Purpose**: Sample documents for testing
- **Contents**: Various file types for comprehensive testing

### **Output Files**
- **Location**: `../Output/`
- **Purpose**: Generated markdown files
- **Naming**: `{original_filename}_markdown.md`

### **Logs**
- **Location**: `../docs/extraction.log`
- **Purpose**: Detailed processing logs and results

## 🎯 Expected Results

### **Successful Processing**
```
[SUCCESS] FedEx Contract.pdf -> FedEx Contract_markdown.md
   File size: 240235 bytes
   Markdown length: 18692 characters
```

### **Error Handling**
```
[ERROR] Unsupported file type: .xyz
[ERROR] HTTP Error 500 for problematic_file.txt
```

## 🔧 Troubleshooting

### **Common Issues**

**API Connection Failed:**
```bash
# Check if API is running
curl http://localhost:5000/health

# Start the API if needed
docker-compose up -d
```

**File Not Found:**
- Verify `../Test Files/` contains the expected files
- Check file permissions and paths

**Virtual Environment Issues:**
```bash
# Windows
.venv\Scripts\Activate.ps1
python --version  # Should show Python 3.x

# Linux/Mac
source .venv/bin/activate
python --version
```

## 📈 Performance Metrics

The scripts provide detailed metrics:
- **File sizes** (input/output)
- **Processing times**
- **Success/failure rates**
- **Content statistics**

## 🔄 Project Structure Integration

```
📦 Markdown Extractor/
├── 📁 docs/                    # Documentation & logs
│   └── extraction.log         # Processing logs
├── 📁 scripts/                # Test scripts (this folder)
│   ├── test_api.py           # Main API testing
│   ├── extract_markdown.py   # Batch extraction
│   └── README.md             # This documentation
├── 📁 Test Files/             # Input test data
├── 📁 Output/                 # Generated markdown
├── 📁 api/                    # Core application
└── 📁 models/                 # Model files
```

## 🎉 Success Indicators

- **6+ successful conversions** from test files
- **Proper markdown formatting** in output files
- **Detailed logging** in `../docs/extraction.log`
- **No crashes or hangs** during processing

## 🚀 Next Steps

1. **Review outputs** in `../Output/` folder
2. **Check logs** in `../docs/extraction.log`
3. **Customize scripts** for your specific needs
4. **Add new test files** to `../Test Files/`

The test scripts provide comprehensive validation of your Markdown Extractor API across all supported file types!
