#!/usr/bin/env python3
"""
Test script to extract markdown from PDF using the deployed Docling API
"""

import requests
import json
import os
import sys
from pathlib import Path

# Configuration
API_BASE_URL = "http://31.97.115.105:5000"
TEST_FILES_DIR = Path("../Test Files")
OUTPUT_DIR = Path("../Output")

def test_api_health():
    """Test if the API is healthy and running"""
    print("🔍 Testing API health...")
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            health_data = response.json()
            print(f"✅ API is healthy: {health_data}")
            return True
        else:
            print(f"❌ API health check failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to API: {e}")
        return False

def test_api_info():
    """Get API information"""
    print("\n📋 Getting API information...")
    try:
        response = requests.get(f"{API_BASE_URL}/", timeout=10)
        if response.status_code == 200:
            api_info = response.json()
            print(f"✅ API Info: {json.dumps(api_info, indent=2)}")
            return True
        else:
            print(f"❌ Failed to get API info: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Error getting API info: {e}")
        return False

def test_supported_formats():
    """Get supported file formats"""
    print("\n📄 Getting supported formats...")
    try:
        response = requests.get(f"{API_BASE_URL}/supported-formats", timeout=10)
        if response.status_code == 200:
            formats = response.json()
            print("✅ Supported formats:")
            for fmt in formats.get('formats', []):
                print(f"  - {fmt.get('extension', 'Unknown')}: {fmt.get('description', 'No description')}")
            return True
        else:
            print(f"❌ Failed to get supported formats: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Error getting supported formats: {e}")
        return False

def extract_markdown_from_pdf(pdf_path):
    """Extract markdown from a PDF file"""
    print(f"\n📄 Extracting markdown from: {pdf_path.name}")
    
    if not pdf_path.exists():
        print(f"❌ File not found: {pdf_path}")
        return None
    
    try:
        # Prepare the file for upload
        with open(pdf_path, 'rb') as file:
            files = {'file': (pdf_path.name, file, 'application/pdf')}
            
            print(f"📤 Uploading {pdf_path.name} to API...")
            response = requests.post(
                f"{API_BASE_URL}/convert",
                files=files,
                timeout=60  # Longer timeout for file processing
            )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                print(f"✅ Conversion successful!")
                print(f"📊 File: {result.get('filename', 'Unknown')}")
                print(f"📊 Type: {result.get('file_type', 'Unknown')}")
                print(f"📊 Markdown length: {result.get('markdown_length', 0)} characters")
                
                # Print metadata if available
                metadata = result.get('metadata', {})
                if metadata:
                    print(f"📊 Metadata: {json.dumps(metadata, indent=2)}")
                
                return result.get('markdown', '')
            else:
                print(f"❌ Conversion failed: {result}")
                return None
        else:
            print(f"❌ API request failed: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Error during conversion: {e}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return None

def save_markdown_output(markdown_content, original_filename):
    """Save the extracted markdown to a file"""
    if not markdown_content:
        print("❌ No markdown content to save")
        return None
    
    # Create output directory if it doesn't exist
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # Generate output filename
    base_name = Path(original_filename).stem
    output_file = OUTPUT_DIR / f"{base_name}_docling_extracted.md"
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(markdown_content)
        
        print(f"💾 Markdown saved to: {output_file}")
        return output_file
    except Exception as e:
        print(f"❌ Error saving markdown: {e}")
        return None

def main():
    """Main test function"""
    print("🚀 Docling PDF Extraction Test Script")
    print("=" * 50)
    
    # Test API connectivity
    if not test_api_health():
        print("\n❌ API is not accessible. Please check your VPS deployment.")
        sys.exit(1)
    
    # Get API information
    test_api_info()
    
    # Get supported formats
    test_supported_formats()
    
    # Find PDF files in Test Files directory
    pdf_files = list(TEST_FILES_DIR.glob("*.pdf"))
    
    if not pdf_files:
        print(f"\n❌ No PDF files found in {TEST_FILES_DIR}")
        sys.exit(1)
    
    print(f"\n📁 Found {len(pdf_files)} PDF file(s):")
    for pdf_file in pdf_files:
        print(f"  - {pdf_file.name}")
    
    # Test with the first PDF file
    test_pdf = pdf_files[0]
    print(f"\n🎯 Testing with: {test_pdf.name}")
    
    # Extract markdown
    markdown_content = extract_markdown_from_pdf(test_pdf)
    
    if markdown_content:
        # Save the output
        output_file = save_markdown_output(markdown_content, test_pdf.name)
        
        # Show a preview of the markdown
        print(f"\n📖 Markdown Preview (first 500 characters):")
        print("-" * 50)
        print(markdown_content[:500])
        if len(markdown_content) > 500:
            print("...")
        print("-" * 50)
        
        print(f"\n✅ Test completed successfully!")
        print(f"📄 Original file: {test_pdf}")
        print(f"📄 Output file: {output_file}")
        print(f"📊 Total characters: {len(markdown_content)}")
    else:
        print(f"\n❌ Test failed - no markdown extracted")
        sys.exit(1)

if __name__ == "__main__":
    main()
