#!/usr/bin/env python3
"""
Markdown Extraction Script
Processes all files in the Test Files folder and outputs markdown to an output folder
"""

import os
import json
import requests
from pathlib import Path
import time

# Configuration
API_URL = "http://localhost:5000"
TEST_FILES_DIR = Path("../Test Files")
OUTPUT_DIR = Path("../Output")
LOG_FILE = Path("../docs/extraction.log")

def log_message(message, level="INFO"):
    """Log messages to both console and file"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {level}: {message}"

    print(log_entry)

    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(log_entry + '\n')

def create_output_directory():
    """Create output directory if it doesn't exist"""
    OUTPUT_DIR.mkdir(exist_ok=True)
    log_message(f"Output directory created/verified: {OUTPUT_DIR}")

def test_api_health():
    """Test if the API is running and healthy"""
    try:
        response = requests.get(f"{API_URL}/health", timeout=10)
        if response.status_code == 200:
            health_data = response.json()
            log_message(f"API Health: {health_data}")
            return True
        else:
            log_message(f"API Health check failed: {response.status_code}", "ERROR")
            return False
    except Exception as e:
        log_message(f"API Health check error: {e}", "ERROR")
        return False

def extract_markdown_from_file(file_path):
    """Extract markdown from a single file"""
    file_path = Path(file_path)

    if not file_path.exists():
        log_message(f"File not found: {file_path}", "ERROR")
        return None

    # Create output filename
    output_filename = f"{file_path.stem}_markdown.md"
    output_path = OUTPUT_DIR / output_filename

    try:
        # Open and send the file
        with open(file_path, 'rb') as f:
            files = {'file': f}

            log_message(f"Processing: {file_path.name}")

            # Make the API request
            response = requests.post(f"{API_URL}/convert", files=files, timeout=300)

            if response.status_code == 200:
                result = response.json()

                if result.get('success'):
                    # Extract markdown content
                    markdown_content = result.get('markdown', '')

                    # Save to output file
                    with open(output_path, 'w', encoding='utf-8') as output_file:
                        output_file.write(markdown_content)

                    log_message(f"[SUCCESS] {file_path.name} -> {output_filename}")
                    log_message(f"   File size: {file_path.stat().st_size} bytes")
                    log_message(f"   Markdown length: {len(markdown_content)} characters")

                    if 'metadata' in result and result['metadata']:
                        metadata = result['metadata']
                        if metadata.get('pages'):
                            log_message(f"   Pages: {metadata['pages']}")
                        if metadata.get('title'):
                            log_message(f"   Title: {metadata['title']}")

                    return {
                        'success': True,
                        'input_file': str(file_path),
                        'output_file': str(output_path),
                        'markdown_length': len(markdown_content),
                        'metadata': metadata
                    }
                else:
                    log_message(f"[ERROR] API Error for {file_path.name}: {result.get('detail', 'Unknown error')}", "ERROR")
                    return {'success': False, 'error': result.get('detail')}
            else:
                error_text = response.text
                log_message(f"[ERROR] HTTP Error {response.status_code} for {file_path.name}: {error_text}", "ERROR")
                return {'success': False, 'error': f"HTTP {response.status_code}: {error_text}"}

    except requests.exceptions.Timeout:
        log_message(f"[ERROR] Timeout processing {file_path.name}", "ERROR")
        return {'success': False, 'error': 'Request timeout'}
    except Exception as e:
        log_message(f"[ERROR] Unexpected error processing {file_path.name}: {e}", "ERROR")
        return {'success': False, 'error': str(e)}

def main():
    """Main extraction function"""
    log_message("=" * 60)
    log_message("Markdown Extraction Script Started")
    log_message("=" * 60)

    # Create output directory
    create_output_directory()

    # Test API health
    if not test_api_health():
        log_message("❌ API is not available. Please ensure the API is running on localhost:5000", "ERROR")
        return

    # Get all files from Test Files directory
    if not TEST_FILES_DIR.exists():
        log_message(f"❌ Test Files directory not found: {TEST_FILES_DIR}", "ERROR")
        return

    # Supported file extensions
    supported_extensions = {'.pdf', '.docx', '.doc', '.png', '.jpg', '.jpeg', '.tiff', '.txt', '.html'}

    # Find all supported files
    test_files = []
    for file_path in TEST_FILES_DIR.iterdir():
        if file_path.is_file() and file_path.suffix.lower() in supported_extensions:
            test_files.append(file_path)

    if not test_files:
        log_message(f"❌ No supported files found in {TEST_FILES_DIR}", "ERROR")
        return

    log_message(f"Found {len(test_files)} files to process:")
    for file in test_files:
        log_message(f"  - {file.name}")

    # Process each file
    results = []
    successful = 0
    failed = 0

    for file_path in test_files:
        result = extract_markdown_from_file(file_path)
        results.append(result)

        if result and result.get('success'):
            successful += 1
        else:
            failed += 1

        # Small delay between requests to avoid overwhelming the API
        time.sleep(1)

    # Summary
    log_message("=" * 60)
    log_message("Extraction Summary")
    log_message("=" * 60)
    log_message(f"Total files processed: {len(results)}")
    log_message(f"[SUCCESS] Successful: {successful}")
    log_message(f"[ERROR] Failed: {failed}")

    if successful > 0:
        log_message(f"\nOutput files created in: {OUTPUT_DIR}")
        log_message("Files generated:")
        for result in results:
            if result and result.get('success'):
                log_message(f"  - {Path(result['output_file']).name}")

    log_message("=" * 60)
    log_message("Markdown Extraction Script Completed")
    log_message("=" * 60)

    return results

if __name__ == "__main__":
    main()
