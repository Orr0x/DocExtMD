#!/usr/bin/env python3
"""
Script to download alternative Docling models that work better with LM Studio
"""

import requests
import os
from pathlib import Path

# Alternative Docling models that work better with LM Studio
MODELS = {
    "docling-q4_0": {
        "url": "https://huggingface.co/gguf-org/docling-gguf/resolve/main/docling-q4_0.gguf",
        "size": "198MB",
        "description": "Q4 quantization - Better LM Studio compatibility"
    },
    "docling-q5_0": {
        "url": "https://huggingface.co/gguf-org/docling-gguf/resolve/main/docling-q5_0.gguf",
        "size": "248MB",
        "description": "Q5 quantization - Balance of size and quality"
    },
    "docling-q6_k": {
        "url": "https://huggingface.co/gguf-org/docling-gguf/resolve/main/docling-q6_k.gguf",
        "size": "298MB",
        "description": "Q6 K-quantization - Good quality with smaller size"
    },
    "docling-f16": {
        "url": "https://huggingface.co/gguf-org/docling-gguf/resolve/main/docling-f16.gguf",
        "size": "792MB",
        "description": "Full precision - Highest quality but largest size"
    }
}

def download_file(url, filename):
    """Download a file with progress indicator"""
    print(f"Downloading {filename}...")

    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()

        total_size = int(response.headers.get('content-length', 0))

        with open(filename, 'wb') as f:
            downloaded = 0
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)

                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\rProgress: {percent:.1f}%", end="", flush=True)

        print(f"\n✅ Downloaded: {filename}")
        return True

    except Exception as e:
        print(f"\n❌ Download failed: {e}")
        return False

def main():
    print("Alternative Docling Models for LM Studio")
    print("=" * 50)

    # Show current model
    models_dir = Path("models")
    current_model = models_dir / "docling-q8_0.gguf"
    if current_model.exists():
        size_mb = current_model.stat().st_size / (1024 * 1024)
        print(f"Current model: docling-q8_0.gguf ({size_mb:.0f}MB)")

    print("\nAvailable alternatives:")
    for i, (name, info) in enumerate(MODELS.items(), 1):
        print(f"{i}. {name} - {info['size']} - {info['description']}")

    print("\nDownloading recommended model for LM Studio: docling-q4_0")
    print("This is the most compatible with LM Studio and smaller than Q8.")

    # Create models directory if it doesn't exist
    models_dir.mkdir(exist_ok=True)

    # Download the recommended Q4 model
    recommended_model = "docling-q4_0"
    selected_info = MODELS[recommended_model]

    filename = models_dir / f"{recommended_model}.gguf"
    if filename.exists():
        print(f"{recommended_model}.gguf already exists. Skipping download.")
    else:
        download_file(selected_info["url"], str(filename))

    print("\nDownload complete!")
    print(f"Downloaded: {recommended_model}.gguf ({selected_info['size']})")
    print("\nTo use with LM Studio:")
    print("1. Open LM Studio")
    print("2. Go to 'My Models' tab")
    print("3. Click 'Add Model' and select the downloaded .gguf file")
    print("4. The model should load successfully")

    print("\nOther models are also available if you need different quality/size trade-offs:")
    for name, info in MODELS.items():
        if name != recommended_model:
            print(f"- {name}: {info['size']} - {info['description']}")

if __name__ == "__main__":
    main()
