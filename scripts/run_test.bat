@echo off
echo 🚀 Running Docling PDF Extraction Test...
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Python found, running Python test script...
    python test_pdf_extraction.py
) else (
    echo ⚠️  Python not found, trying PowerShell...
    powershell -ExecutionPolicy Bypass -File test_pdf_extraction.ps1
)

echo.
echo Press any key to exit...
pause >nul
