#!/bin/bash

# Markdown Extractor API Test Script
# Tests various file types from the "Test Files" folder

API_URL="http://localhost:5000"
TEST_FILES_DIR="Test Files"

echo "🧪 Markdown Extractor API Test Script"
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test health endpoint
echo -e "\n${YELLOW}1. Testing Health Endpoint${NC}"
curl -s "$API_URL/health" | jq .

# Test supported formats
echo -e "\n${YELLOW}2. Testing Supported Formats${NC}"
curl -s "$API_URL/supported-formats" | jq .

# Test PDF file
echo -e "\n${YELLOW}3. Testing PDF File Conversion${NC}"
echo "File: $TEST_FILES_DIR/FedEx Contract.pdf"
curl -s -X POST "$API_URL/convert" \
  -F "file=@$TEST_FILES_DIR/FedEx Contract.pdf" \
  -H "Accept: application/json" | jq .

# Test HTML file
echo -e "\n${YELLOW}4. Testing HTML File Conversion${NC}"
echo "File: $TEST_FILES_DIR/RightFit Interiors — Bespoke Carpentry & Joinery.html"
curl -s -X POST "$API_URL/convert" \
  -F "file=@$TEST_FILES_DIR/RightFit Interiors — Bespoke Carpentry & Joinery.html" \
  -H "Accept: application/json" | jq .

# Test PNG image
echo -e "\n${YELLOW}5. Testing PNG Image Conversion${NC}"
echo "File: $TEST_FILES_DIR/Screenshot 2025-10-05 012248.png"
curl -s -X POST "$API_URL/convert" \
  -F "file=@$TEST_FILES_DIR/Screenshot 2025-10-05 012248.png" \
  -H "Accept: application/json" | jq .

# Test DOCX file (if it exists)
if [ -f "$TEST_FILES_DIR/FedEx Contract.pdf.docx" ]; then
    echo -e "\n${YELLOW}6. Testing DOCX File Conversion${NC}"
    echo "File: $TEST_FILES_DIR/FedEx Contract.pdf.docx"
    curl -s -X POST "$API_URL/convert" \
      -F "file=@$TEST_FILES_DIR/FedEx Contract.pdf.docx" \
      -H "Accept: application/json" | jq .
fi

# Test TXT file (if it exists)
if [ -f "$TEST_FILES_DIR/FedEx Contract.pdf.txt" ]; then
    echo -e "\n${YELLOW}7. Testing TXT File Conversion${NC}"
    echo "File: $TEST_FILES_DIR/FedEx Contract.pdf.txt"
    curl -s -X POST "$API_URL/convert" \
      -F "file=@$TEST_FILES_DIR/FedEx Contract.pdf.txt" \
      -H "Accept: application/json" | jq .
fi

# Test error case - unsupported file type
echo -e "\n${YELLOW}8. Testing Error Case - Unsupported File${NC}"
echo "Creating a test .xyz file..."
echo "test content" > test.xyz
curl -s -X POST "$API_URL/convert" \
  -F "file=@test.xyz" \
  -H "Accept: application/json" | jq .
rm test.xyz

echo -e "\n${GREEN}✅ Test script completed!${NC}"
echo "Check the responses above for conversion results."
