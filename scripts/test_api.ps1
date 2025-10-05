# Markdown Extractor API Test Script (PowerShell)
# Tests various file types from the "Test Files" folder

param(
    [string]$ApiUrl = "http://localhost:5000",
    [string]$TestFilesDir = "Test Files"
)

Write-Host "🧪 Markdown Extractor API Test Script (PowerShell)" -ForegroundColor Blue
Write-Host "=================================================" -ForegroundColor Blue

# Function to test GET endpoints
function Test-Endpoint {
    param(
        [string]$Endpoint,
        [string]$Description
    )

    Write-Host "`n$Description" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl$Endpoint" -Method Get
        $response | ConvertTo-Json -Depth 3
        return $response
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to test file conversion
function Test-FileConversion {
    param(
        [string]$FilePath,
        [string]$Description
    )

    Write-Host "`n$Description" -ForegroundColor Yellow
    Write-Host "File: $FilePath" -ForegroundColor Gray

    if (!(Test-Path $FilePath)) {
        Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
        return $null
    }

    try {
        $fileSize = (Get-Item $FilePath).Length
        $response = Invoke-RestMethod -Uri "$ApiUrl/convert" -Method Post -Form @{
            file = Get-Item $FilePath
        }

        if ($response.success) {
            Write-Host "✅ Conversion successful!" -ForegroundColor Green
            Write-Host "   Original size: $fileSize bytes" -ForegroundColor Gray
            Write-Host "   Markdown length: $($response.markdown_length) characters" -ForegroundColor Gray

            if ($response.metadata -and $response.metadata.pages) {
                Write-Host "   Pages: $($response.metadata.pages)" -ForegroundColor Gray
            }
            if ($response.metadata -and $response.metadata.title) {
                Write-Host "   Title: $($response.metadata.title)" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "❌ Conversion failed!" -ForegroundColor Red
            Write-Host "   Error: $($response.detail)" -ForegroundColor Red
        }

        return $response
    }
    catch {
        Write-Host "❌ Request error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Check if test files directory exists
if (!(Test-Path $TestFilesDir)) {
    Write-Host "❌ Test Files directory not found: $TestFilesDir" -ForegroundColor Red
    exit 1
}

# Test 1: Health check
Test-Endpoint "/health" "1. Testing Health Endpoint"

# Test 2: Supported formats
Test-Endpoint "/supported-formats" "2. Testing Supported Formats"

# Test 3: PDF file (FedEx Contract)
$fedexPdf = Join-Path $TestFilesDir "FedEx Contract.pdf"
Test-FileConversion $fedexPdf "3. Testing PDF File Conversion"

# Test 4: HTML file (RightFit Interiors)
$rightfitHtml = Join-Path $TestFilesDir "RightFit Interiors — Bespoke Carpentry & Joinery.html"
Test-FileConversion $rightfitHtml "4. Testing HTML File Conversion"

# Test 5: PNG image
$screenshotPng = Join-Path $TestFilesDir "Screenshot 2025-10-05 012248.png"
Test-FileConversion $screenshotPng "5. Testing PNG Image Conversion"

# Test 6: DOCX file (if exists)
$fedexDocx = Join-Path $TestFilesDir "FedEx Contract.pdf.docx"
if (Test-Path $fedexDocx) {
    Test-FileConversion $fedexDocx "6. Testing DOCX File Conversion"
}

# Test 7: TXT file (if exists)
$fedexTxt = Join-Path $TestFilesDir "FedEx Contract.pdf.txt"
if (Test-Path $fedexTxt) {
    Test-FileConversion $fedexTxt "7. Testing TXT File Conversion"
}

# Test 8: Error case - unsupported file
Write-Host "`n8. Testing Error Case - Unsupported File" -ForegroundColor Yellow
$testFile = "test_unsupported.xyz"
try {
    "This is a test file with unsupported extension" | Out-File -FilePath $testFile -Encoding UTF8

    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl/convert" -Method Post -Form @{
            file = Get-Item $testFile
        }

        if ($response.detail -like "*Unsupported file type*") {
            Write-Host "✅ Correctly rejected unsupported file" -ForegroundColor Green
            Write-Host "   Error: $($response.detail)" -ForegroundColor Gray
        }
        else {
            Write-Host "❌ Unexpected response for unsupported file" -ForegroundColor Red
            Write-Host "   Status: $($response | ConvertTo-Json -Depth 1)" -ForegroundColor Red
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
            Write-Host "✅ Correctly rejected unsupported file" -ForegroundColor Green
            Write-Host "   Error: $($errorBody.detail)" -ForegroundColor Gray
        }
        else {
            Write-Host "❌ Unexpected error for unsupported file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
finally {
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
    }
}

# Summary
Write-Host "`n✅ PowerShell test script completed!" -ForegroundColor Green
Write-Host "Check the responses above for detailed conversion results." -ForegroundColor Gray
