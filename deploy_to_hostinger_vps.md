# 🚀 Deploy Markdown Extractor to Hostinger VPS

Complete guide to deploy your Docker-based Markdown Extractor API to a Hostinger VPS.

## 📋 Prerequisites

- ✅ Hostinger VPS with Ubuntu 24.04 LTS
- ✅ SSH access to VPS (root@31.97.115.105)
- ✅ Docker and Docker Compose installed on VPS
- ✅ Project files ready for deployment

## 🔧 Step 1: VPS Preparation

### Install Docker and Docker Compose

SSH into your VPS and install Docker:

```bash
# Update package list
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to docker group (optional, for non-root usage)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker-compose --version
```

### Configure Firewall

```bash
# Check current firewall status
sudo ufw status

# Allow port 5000 for your API
sudo ufw allow 5000/tcp

# Allow SSH (should already be allowed)
sudo ufw allow 22/tcp

# Enable firewall if not already enabled
sudo ufw enable

# Verify rules
sudo ufw status numbered
```

## 📦 Step 2: Deploy Application

### Option A: Manual Deployment

```bash
# 1. Create project directory
mkdir -p ~/markdown-extractor
cd ~/markdown-extractor

# 2. Copy project files (from your local machine)
# Use scp, rsync, or git clone to transfer files
```

### Option B: Automated Deployment (Recommended)

Use the deployment script:

```bash
# Download and run the deployment script
wget https://raw.githubusercontent.com/your-repo/markdown-extractor-deploy/main/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

## 🔨 Step 3: Build and Run Container

```bash
# Navigate to project directory
cd ~/markdown-extractor

# Build the Docker image
docker-compose build

# Start the service
docker-compose up -d

# Verify container is running
docker-compose ps

# Check logs
docker-compose logs -f markdown-extractor
```

## ✅ Step 4: Verify Deployment

### Test API Endpoints

```bash
# Health check
curl http://localhost:5000/health

# API information
curl http://localhost:5000/

# Supported formats
curl http://localhost:5000/supported-formats
```

### Expected Responses

**Health Check:**
```json
{"status":"healthy","model":"docling-q4_0","ready":true}
```

**API Info:**
```json
{
  "service": "Markdown Extractor API",
  "status": "running",
  "version": "1.0.0",
  "model": "docling-q4_0 (258M parameters)"
}
```

## 🌐 Step 5: External Access

Your API is now accessible from external machines at:
```
http://31.97.115.105:5000
```

### Test from Local Machine

```bash
# Test health endpoint
curl http://31.97.115.105:5000/health

# Test file conversion
curl -X POST http://31.97.115.105:5000/convert \
  -F "file=@/path/to/document.pdf" \
  -H "Accept: application/json"
```

## 🔒 Step 6: Security Configuration (Optional)

### Add Basic Authentication

Install and configure Nginx as reverse proxy:

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/markdown-extractor
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Increase timeout for large file processing
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;

        # Increase max body size for file uploads
        client_max_body_size 50M;
    }
}
```

Enable the site:
```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/markdown-extractor /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### SSL Certificate (Optional)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com
```

## 📊 Step 7: Monitoring and Maintenance

### Useful Commands

```bash
# View logs in real-time
docker-compose logs -f

# Check resource usage
docker stats markdown-extractor

# Restart service
docker-compose restart

# Stop service
docker-compose down

# Update deployment
docker-compose down
docker-compose pull  # If using pre-built images
docker-compose up -d

# Check disk usage
df -h
```

### Log Locations

```bash
# Container logs
docker-compose logs markdown-extractor

# System logs
sudo journalctl -u docker -f
```

## 🚨 Troubleshooting

### Container Won't Start

```bash
# Check logs for errors
docker-compose logs markdown-extractor

# Check if port 5000 is available
sudo netstat -tulpn | grep 5000

# Check Docker service status
sudo systemctl status docker
```

### Memory Issues

```bash
# Check memory usage
free -h

# Check Docker memory usage
docker system df

# Reduce memory limits in docker-compose.yml
# Edit: memory: 2G (from 3G)
```

### Network Issues

```bash
# Check firewall status
sudo ufw status

# Test connectivity
curl -v http://localhost:5000/health

# Check if container is listening
sudo netstat -tulpn | grep 5000
```

## 📈 Performance Optimization

### Resource Monitoring

```bash
# Monitor CPU and memory
htop

# Monitor disk I/O
iotop

# Monitor network
iftop
```

### Optimization Tips

1. **Memory**: Reduce Docker memory limits if experiencing OOM
2. **CPU**: Monitor CPU usage and adjust limits
3. **Storage**: Clean up unused Docker images: `docker system prune`
4. **Network**: Use Nginx for better performance and SSL

## 🔄 Step 8: Update Deployment

When you make changes to your code:

```bash
# On your VPS
cd ~/markdown-extractor

# Pull latest changes (if using git)
git pull

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d

# Verify update
curl http://localhost:5000/health
```

## 🎯 Success Criteria

Your deployment is successful when:

- ✅ Container is running: `docker-compose ps` shows "Up" status
- ✅ Health check passes: `curl http://localhost:5000/health` returns healthy status
- ✅ API is accessible externally: `curl http://31.97.115.105:5000/` returns service info
- ✅ Document conversion works: Test file successfully converts to markdown
- ✅ Logs show no errors: `docker-compose logs` displays normal operation

## 🚀 Next Steps

1. **Test with various document types** from your local machine
2. **Set up domain and SSL** (optional but recommended)
3. **Configure monitoring** for production use
4. **Set up automated backups** if needed
5. **Consider load balancing** for high-traffic scenarios

## 📞 Support

For Hostinger-specific issues:
- Check Hostinger VPS documentation
- Contact Hostinger support
- Review VPS console and monitoring tools

Your Markdown Extractor API is now deployed and ready to convert documents from anywhere! 🎉
