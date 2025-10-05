#!/usr/bin/env python3
"""
Markdown Extractor API Test Script
Tests various file types from the "Test Files" folder using Python requests
Updated to work with virtual environment
"""

import os
import json
import requests
from pathlib import Path

# Configuration
API_URL = "http://localhost:5000"
TEST_FILES_DIR = Path("../Test Files")

def print_colored(text, color_code):
    """Print colored text to terminal"""
    colors = {
        'green': '\033[92m',
        'red': '\033[91m',
        'yellow': '\033[93m',
        'blue': '\033[94m',
        'reset': '\033[0m'
    }
    print(f"{colors.get(color_code, '')}{text}{colors['reset']}")

def print_header(text):
    """Print header without Unicode characters"""
    print(f"{'='*50}")
    print(f"Markdown Extractor API Test Script (Python)")
    print(f"{'='*50}")

def test_endpoint(endpoint, description):
    """Test a GET endpoint"""
    print_colored(f"\n{description}", 'yellow')
    try:
        response = requests.get(f"{API_URL}{endpoint}")
        response.raise_for_status()
        data = response.json()
        print(json.dumps(data, indent=2))
        return data
    except requests.exceptions.RequestException as e:
        print_colored(f"❌ Error: {e}", 'red')
        return None

def test_file_conversion(file_path, description):
    """Test file conversion with a specific file"""
    print_colored(f"\n{description}", 'yellow')
    print(f"File: {file_path}")

    if not file_path.exists():
        print_colored(f"❌ File not found: {file_path}", 'red')
        return None

    try:
        with open(file_path, 'rb') as f:
            files = {'file': f}
            response = requests.post(f"{API_URL}/convert", files=files)
            response.raise_for_status()
            data = response.json()

            # Print summary
            if data.get('success'):
                print_colored("[SUCCESS] Conversion successful!", 'green')
                print(f"   Original size: {file_path.stat().st_size} bytes")
                print(f"   Markdown length: {data.get('markdown_length', 0)} characters")
                if 'metadata' in data and data['metadata']:
                    metadata = data['metadata']
                    if metadata.get('pages'):
                        print(f"   Pages: {metadata['pages']}")
                    if metadata.get('title'):
                        print(f"   Title: {metadata['title']}")
            else:
                print_colored("[ERROR] Conversion failed!", 'red')
                print(f"   Error: {data.get('detail', 'Unknown error')}")

            return data

    except requests.exceptions.RequestException as e:
        print_colored(f"[ERROR] Request error: {e}", 'red')
        return None
    except Exception as e:
        print_colored(f"[ERROR] Unexpected error: {e}", 'red')
        return None

def main():
    """Main test function"""
    print_header("")

    # Check if test files directory exists
    if not TEST_FILES_DIR.exists():
        print_colored(f"[ERROR] Test Files directory not found: {TEST_FILES_DIR}", 'red')
        return

    # Test 1: Health check
    test_endpoint("/health", "1. Testing Health Endpoint")

    # Test 2: Supported formats
    test_endpoint("/supported-formats", "2. Testing Supported Formats")

    # Test 3: PDF file (FedEx Contract)
    pdf_file = TEST_FILES_DIR / "FedEx Contract.pdf"
    test_file_conversion(pdf_file, "3. Testing PDF File Conversion")

    # Test 4: HTML file (RightFit Interiors)
    html_file = TEST_FILES_DIR / "RightFit Interiors — Bespoke Carpentry & Joinery.html"
    test_file_conversion(html_file, "4. Testing HTML File Conversion")

    # Test 5: PNG image
    png_file = TEST_FILES_DIR / "Screenshot 2025-10-05 012248.png"
    test_file_conversion(png_file, "5. Testing PNG Image Conversion")

    # Test 6: DOCX file (if exists)
    docx_file = TEST_FILES_DIR / "FedEx Contract.pdf.docx"
    if docx_file.exists():
        test_file_conversion(docx_file, "6. Testing DOCX File Conversion")

    # Test 7: TXT file (if exists)
    txt_file = TEST_FILES_DIR / "FedEx Contract.pdf.txt"
    if txt_file.exists():
        test_file_conversion(txt_file, "7. Testing TXT File Conversion")

    # Test 8: Error case - unsupported file
    print_colored("\n8. Testing Error Case - Unsupported File", 'yellow')
    error_file = Path("test_unsupported.xyz")
    try:
        error_file.write_text("This is a test file with unsupported extension")
        with open(error_file, 'rb') as f:
            files = {'file': f}
            response = requests.post(f"{API_URL}/convert", files=files)
            if response.status_code == 400:
                data = response.json()
                print_colored("[SUCCESS] Correctly rejected unsupported file", 'green')
                print(f"   Error: {data.get('detail', 'Unknown error')}")
            else:
                print_colored("[ERROR] Unexpected response for unsupported file", 'red')
                print(f"   Status: {response.status_code}")
    except Exception as e:
        print_colored(f"[ERROR] Error testing unsupported file: {e}", 'red')
    finally:
        if error_file.exists():
            error_file.unlink()

    # Summary
    print_colored("\n[SUCCESS] Python test script completed!", 'green')
    print("Check the responses above for detailed conversion results.")

if __name__ == "__main__":
    main()
