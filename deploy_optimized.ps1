# PowerShell script to deploy optimized Docling API to VPS
# This script updates the VPS with CPU-optimized version

param(
    [string]$VPS_HOST = "31.97.115.105",
    [string]$VPS_USER = "root",
    [string]$SSH_KEY = "C:\Users\james\.ssh\id_ed25519"
)

Write-Host "🚀 Deploying Optimized DocExtMD to VPS..." -ForegroundColor Green
Write-Host "VPS: $VPS_USER@$VPS_HOST" -ForegroundColor Cyan

# Verify local files exist
$requiredFiles = @(
    "api/main.py",
    "docker-compose.yml", 
    "requirements.txt",
    "models/docling-q4_0.gguf"
)

Write-Host "✅ Checking local files..." -ForegroundColor Yellow
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Missing required file: $file" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ All required files found" -ForegroundColor Green

# Create deployment package
Write-Host "📦 Creating optimized deployment package..." -ForegroundColor Yellow
$deployDir = "DocExtMD-optimized"
if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Copy optimized files
Copy-Item "api" -Destination "$deployDir\" -Recurse
Copy-Item "models" -Destination "$deployDir\" -Recurse
Copy-Item "docker-compose.yml" -Destination "$deployDir\"
Copy-Item "requirements.txt" -Destination "$deployDir\"
Copy-Item "Dockerfile" -Destination "$deployDir\"

# Create deployment zip
$zipFile = "DocExtMD-optimized.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}
Compress-Archive -Path "$deployDir\*" -DestinationPath $zipFile
Write-Host "✅ Optimized deployment package created: $zipFile" -ForegroundColor Green

# Upload to VPS
Write-Host "📤 Uploading optimized version to VPS..." -ForegroundColor Yellow
scp -i $SSH_KEY $zipFile "${VPS_USER}@${VPS_HOST}:~/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Files uploaded to VPS" -ForegroundColor Green

# Execute deployment on VPS
Write-Host "🔧 Executing optimized deployment on VPS..." -ForegroundColor Yellow
ssh -i $SSH_KEY "${VPS_USER}@${VPS_HOST}" @"
    echo '📋 Starting optimized VPS deployment...'
    
    # Stop existing service
    echo '🛑 Stopping existing service...'
    cd ~/DocExtMD
    docker-compose down || true
    
    # Backup current version
    echo '💾 Creating backup...'
    if [ -d ~/DocExtMD ]; then
        mv ~/DocExtMD ~/DocExtMD-backup-\$(date +%Y%m%d_%H%M%S) || true
    fi
    
    # Extract new version
    echo '📦 Extracting optimized version...'
    unzip -o ~/DocExtMD-optimized.zip -d ~/
    mv ~/DocExtMD-optimized ~/DocExtMD
    cd ~/DocExtMD
    
    # Verify q4_0 model exists
    echo '🔍 Verifying q4_0 model...'
    if [ ! -f models/docling-q4_0.gguf ]; then
        echo '❌ q4_0 model not found!'
        exit 1
    fi
    echo '✅ q4_0 model verified'
    
    # Build and start optimized service
    echo '🔨 Building optimized Docker image...'
    docker-compose build --no-cache
    
    echo '🚀 Starting optimized service...'
    docker-compose up -d
    
    # Wait for service to start
    echo '⏳ Waiting for service to start...'
    sleep 15
    
    # Test health endpoint
    echo '🧪 Testing optimized service...'
    curl -f http://localhost:5000/health || {
        echo '❌ Health check failed'
        docker-compose logs
        exit 1
    }
    
    echo '✅ Optimized service is running!'
    echo '📊 Service info:'
    curl -s http://localhost:5000/ | jq . || curl -s http://localhost:5000/
    
    # Cleanup
    rm -f ~/DocExtMD-optimized.zip
    echo '🧹 Cleanup completed'
    
    echo '🎉 Optimized deployment completed successfully!'
    echo '🌐 Your optimized Docling API is now running at: http://$VPS_HOST:5000'
    echo '🔧 To manage the service:'
    echo '   cd ~/DocExtMD'
    echo '   docker-compose logs -f    # View logs'
    echo '   docker-compose restart    # Restart service'
    echo '   docker-compose down       # Stop service'
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "🎉 Optimized deployment completed successfully!" -ForegroundColor Green
    Write-Host "🌐 Your optimized Docling API is now running at: http://$VPS_HOST:5000" -ForegroundColor Cyan
    Write-Host "🧪 Test it with: curl http://$VPS_HOST:5000/health" -ForegroundColor Yellow
} else {
    Write-Host "❌ Optimized deployment failed" -ForegroundColor Red
    exit 1
}

# Cleanup local files
Write-Host "🧹 Cleaning up local files..." -ForegroundColor Yellow
Remove-Item $deployDir -Recurse -Force
Remove-Item $zipFile -Force
Write-Host "✅ Local cleanup completed" -ForegroundColor Green

Write-Host "`n🎯 Optimization Summary:" -ForegroundColor Magenta
Write-Host "✅ Switched from q8_0 to q4_0 model (50% smaller)" -ForegroundColor Green
Write-Host "✅ Added CPU-optimized converter settings" -ForegroundColor Green
Write-Host "✅ Implemented image compression" -ForegroundColor Green
Write-Host "✅ Added timeout protection (30s images, 60s documents)" -ForegroundColor Green
Write-Host "✅ Enhanced error handling with graceful responses" -ForegroundColor Green
Write-Host "✅ Updated health check to show optimization status" -ForegroundColor Green
