# Nginx Conflict Resolution - VPS Deployment

## Overview

This document details the Nginx configuration conflict encountered during the deployment of the Docling API alongside an existing React application on the Hostinger VPS, and the steps taken to resolve it.

## Problem Description

### Initial Issue
After deploying the Docling API to the VPS, the existing React application (RightFit Interiors) became inaccessible externally, even though it was working locally on the server.

### Root Cause
The issue was caused by **conflicting Nginx server configurations** that were both trying to handle the same domain and IP address on port 80.

## Error Analysis

### 1. Conflicting Server Names Warning
```bash
nginx -t
# Output:
2025/10/05 14:48:01 [warn] 11726#11726: conflicting server name "rightfit-kitchens.co.uk" on 0.0.0.0:80, ignored
2025/10/05 14:48:01 [warn] 11726#11726: conflicting server name "31.97.115.105" on 0.0.0.0:80, ignored
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 2. Multiple Enabled Configurations
```bash
ls -la /etc/nginx/sites-enabled/
# Output:
lrwxrwxrwx 1 root root   44 Oct  5 14:47 rightfit-kitchens -> /etc/nginx/sites-available/rightfit-kitchens
lrwxrwxrwx 1 root root   50 Sep 10 20:25 rightfit-kitchens.co.uk -> /etc/nginx/sites-available/rightfit-kitchens.co.uk
```

### 3. Duplicate Server Blocks
Two separate configuration files were both trying to serve the same domain:

**File 1: `/etc/nginx/sites-available/rightfit-kitchens`**
```nginx
server {
    listen 80;
    server_name 31.97.115.105 rightfit-kitchens.co.uk;
    # ... configuration with Docling API proxy
}
```

**File 2: `/etc/nginx/sites-available/rightfit-kitchens.co.uk`**
```nginx
server {
    listen 80;
    server_name rightfit-kitchens.co.uk www.rightfit-kitchens.co.uk 31.97.115.105;
    # ... configuration without Docling API proxy
}
```

## Resolution Steps

### Step 1: Identify Conflicting Configurations
```bash
# Check enabled sites
ls -la /etc/nginx/sites-enabled/

# View both configuration files
cat /etc/nginx/sites-available/rightfit-kitchens
cat /etc/nginx/sites-available/rightfit-kitchens.co.uk
```

### Step 2: Remove Duplicate Configuration
```bash
# Remove the older configuration that doesn't include Docling API support
rm /etc/nginx/sites-enabled/rightfit-kitchens.co.uk
```

### Step 3: Verify Single Configuration
```bash
# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx
```

### Step 4: Test Services
```bash
# Test React app locally
curl http://localhost/

# Test Docling API directly
curl http://localhost:5000/health

# Test Docling API via proxy
curl http://localhost/api/docling/health
```

## Final Working Configuration

The resolved configuration in `/etc/nginx/sites-available/rightfit-kitchens`:

```nginx
server {
    listen 80;
    server_name 31.97.115.105 rightfit-kitchens.co.uk;

    # Root directory for React app
    root /var/www/rightfit-kitchens.co.uk;
    index index.html;

    # Main React app - serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Handle static assets with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Docling API - proxy to port 5000
    location /api/docling/ {
        proxy_pass http://localhost:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Increase timeout for file processing
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;

        # Increase max body size for file uploads
        client_max_body_size 50M;
    }
}
```

## Firewall Configuration

### VPS UFW Firewall
```bash
# Open required ports
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 5000/tcp  # Docling API

# Check status
sudo ufw status
```

### Hostinger Cloud Firewall
The following rules were configured in the Hostinger control panel:
- **Accept TCP 80 Any any** - HTTP traffic
- **Accept TCP 443 Any any** - HTTPS traffic  
- **Accept TCP 5000 Any any** - Docling API
- **Accept SSH 22 Any any** - SSH access
- **Drop Any Any Any any** - Default deny rule

## Testing Results

### External Access Tests
```powershell
# React app (should return HTML)
curl http://31.97.115.105/

# Docling API direct (should return JSON)
curl http://31.97.115.105:5000/health

# Docling API via proxy (should return JSON)
curl http://31.97.115.105/api/docling/health
```

### Expected Responses
- **React App**: HTML content with RightFit Interiors website
- **Docling API**: `{"status":"healthy","model":"docling-q8_0","ready":true}`
- **Docling API via Proxy**: Same JSON response as direct access

## Key Lessons Learned

1. **Single Configuration**: Only one Nginx server block should handle each domain/IP combination
2. **Configuration Testing**: Always run `nginx -t` before reloading
3. **Firewall Requirements**: Both VPS and cloud firewalls need to allow traffic
4. **Service Coexistence**: Multiple services can run on the same server with proper proxy configuration

## Troubleshooting Commands

```bash
# Check Nginx status
systemctl status nginx

# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx

# Check listening ports
netstat -tulpn | grep :80
netstat -tulpn | grep :5000

# View Nginx error logs
tail -f /var/log/nginx/error.log

# Check enabled sites
ls -la /etc/nginx/sites-enabled/
```

## Prevention

To avoid similar conflicts in the future:

1. **Document Existing Configurations**: Always check existing Nginx configurations before adding new ones
2. **Use Descriptive Names**: Name configuration files clearly to avoid confusion
3. **Test Incrementally**: Test each change before making additional modifications
4. **Backup Configurations**: Keep backups of working configurations

---

**Date**: October 5, 2025  
**VPS**: Hostinger (31.97.115.105)  
**Services**: RightFit Interiors React App + Docling API  
**Status**: ✅ Resolved - Both services running successfully
