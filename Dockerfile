FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    python-multipart==0.0.6 \
    docling

# Copy API code
COPY api/main.py /app/main.py

# Expose port
EXPOSE 5000

# Start the API server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
