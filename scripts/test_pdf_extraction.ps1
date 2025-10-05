# Test script to extract markdown from PDF using the deployed Docling API
# Usage: .\test_pdf_extraction.ps1

param(
    [string]$ApiUrl = "http://31.97.115.105:5000",
    [string]$TestFilesDir = "..\Test Files",
    [string]$OutputDir = "..\Output"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Docling PDF Extraction Test Script" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Cyan

function Test-ApiHealth {
    Write-Host "🔍 Testing API health..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get -TimeoutSec 10
        Write-Host "✅ API is healthy: $($response | ConvertTo-Json -Compress)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Cannot connect to API: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-ApiInfo {
    Write-Host "`n📋 Getting API information..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl/" -Method Get -TimeoutSec 10
        Write-Host "✅ API Info:" -ForegroundColor Green
        Write-Host ($response | ConvertTo-Json -Depth 3) -ForegroundColor White
        return $true
    }
    catch {
        Write-Host "❌ Error getting API info: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-SupportedFormats {
    Write-Host "`n📄 Getting supported formats..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl/supported-formats" -Method Get -TimeoutSec 10
        Write-Host "✅ Supported formats:" -ForegroundColor Green
        foreach ($format in $response.formats) {
            Write-Host "  - $($format.extension): $($format.description)" -ForegroundColor White
        }
        return $true
    }
    catch {
        Write-Host "❌ Error getting supported formats: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Extract-MarkdownFromPdf {
    param([string]$PdfPath)
    
    Write-Host "`n📄 Extracting markdown from: $(Split-Path $PdfPath -Leaf)" -ForegroundColor Yellow
    
    if (-not (Test-Path $PdfPath)) {
        Write-Host "❌ File not found: $PdfPath" -ForegroundColor Red
        return $null
    }
    
    try {
        # Create multipart form data
        $boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"
        
        $fileBytes = [System.IO.File]::ReadAllBytes($PdfPath)
        $fileName = Split-Path $PdfPath -Leaf
        
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
            "Content-Type: application/pdf",
            "",
            [System.Text.Encoding]::GetEncoding("iso-8859-1").GetString($fileBytes),
            "--$boundary--",
            ""
        ) -join $LF
        
        $bodyBytes = [System.Text.Encoding]::GetEncoding("iso-8859-1").GetBytes($bodyLines)
        
        Write-Host "📤 Uploading $fileName to API..." -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri "$ApiUrl/convert" -Method Post -Body $bodyBytes -ContentType "multipart/form-data; boundary=$boundary" -TimeoutSec 60
        
        if ($response.success) {
            Write-Host "✅ Conversion successful!" -ForegroundColor Green
            Write-Host "📊 File: $($response.filename)" -ForegroundColor White
            Write-Host "📊 Type: $($response.file_type)" -ForegroundColor White
            Write-Host "📊 Markdown length: $($response.markdown_length) characters" -ForegroundColor White
            
            if ($response.metadata) {
                Write-Host "📊 Metadata: $($response.metadata | ConvertTo-Json -Compress)" -ForegroundColor White
            }
            
            return $response.markdown
        }
        else {
            Write-Host "❌ Conversion failed: $($response | ConvertTo-Json)" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "❌ Error during conversion: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Save-MarkdownOutput {
    param([string]$MarkdownContent, [string]$OriginalFilename)
    
    if (-not $MarkdownContent) {
        Write-Host "❌ No markdown content to save" -ForegroundColor Red
        return $null
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Generate output filename
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OriginalFilename)
    $outputFile = Join-Path $OutputDir "${baseName}_docling_extracted.md"
    
    try {
        $MarkdownContent | Out-File -FilePath $outputFile -Encoding UTF8
        Write-Host "💾 Markdown saved to: $outputFile" -ForegroundColor Green
        return $outputFile
    }
    catch {
        Write-Host "❌ Error saving markdown: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Main execution
try {
    # Test API connectivity
    if (-not (Test-ApiHealth)) {
        Write-Host "`n❌ API is not accessible. Please check your VPS deployment." -ForegroundColor Red
        exit 1
    }
    
    # Get API information
    Get-ApiInfo | Out-Null
    
    # Get supported formats
    Get-SupportedFormats | Out-Null
    
    # Find PDF files in Test Files directory
    $pdfFiles = Get-ChildItem -Path $TestFilesDir -Filter "*.pdf" -ErrorAction SilentlyContinue
    
    if (-not $pdfFiles) {
        Write-Host "`n❌ No PDF files found in $TestFilesDir" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n📁 Found $($pdfFiles.Count) PDF file(s):" -ForegroundColor Yellow
    foreach ($pdfFile in $pdfFiles) {
        Write-Host "  - $($pdfFile.Name)" -ForegroundColor White
    }
    
    # Test with the first PDF file
    $testPdf = $pdfFiles[0]
    Write-Host "`n🎯 Testing with: $($testPdf.Name)" -ForegroundColor Yellow
    
    # Extract markdown
    $markdownContent = Extract-MarkdownFromPdf -PdfPath $testPdf.FullName
    
    if ($markdownContent) {
        # Save the output
        $outputFile = Save-MarkdownOutput -MarkdownContent $markdownContent -OriginalFilename $testPdf.Name
        
        # Show a preview of the markdown
        Write-Host "`n📖 Markdown Preview (first 500 characters):" -ForegroundColor Yellow
        Write-Host "-" * 50 -ForegroundColor Cyan
        $preview = if ($markdownContent.Length -gt 500) { $markdownContent.Substring(0, 500) + "..." } else { $markdownContent }
        Write-Host $preview -ForegroundColor White
        Write-Host "-" * 50 -ForegroundColor Cyan
        
        Write-Host "`n✅ Test completed successfully!" -ForegroundColor Green
        Write-Host "📄 Original file: $($testPdf.FullName)" -ForegroundColor White
        Write-Host "📄 Output file: $outputFile" -ForegroundColor White
        Write-Host "📊 Total characters: $($markdownContent.Length)" -ForegroundColor White
    }
    else {
        Write-Host "`n❌ Test failed - no markdown extracted" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "`n❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
