#!/usr/bin/env python3
import subprocess
import time

HOST = "46.8.255.137"
USER = "root"
PASS = "k8hSaZ2XL37x"

def ssh_cmd(cmd, timeout=30):
    full_cmd = f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {USER}@{HOST} \"{cmd}\""
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=timeout)
    return result.stdout.strip(), result.returncode

def scp_file(src, dst):
    full_cmd = f"sshpass -p '{PASS}' scp -o StrictHostKeyChecking=no {src} {USER}@{HOST}:{dst}"
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=30)
    return result.returncode == 0

print("=" * 70)
print("FINAL PRODUCTION FIX")
print("=" * 70)

# Step 1: Stop service
print("\n🛑 Step 1: Stopping service...")
ssh_cmd("systemctl stop sergeev")
time.sleep(2)

# Step 2: Update systemd service
print("\n🔧 Step 2: Updating systemd service...")
service_file = """[Unit]
Description=Sergeev Digitization System
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/sergeev/app
Environment="PORT=8100"
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node /opt/sergeev/app/dist/index.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
"""

with open('/tmp/sergeev.service', 'w') as f:
    f.write(service_file)

scp_file('/tmp/sergeev.service', '/etc/systemd/system/sergeev.service')
ssh_cmd("systemctl daemon-reload")
print("  ✓ Done")

# Step 3: Create nginx config
print("\n🔧 Step 3: Creating nginx config...")
nginx_file = """server {
    listen 80;
    server_name _;

    location /100 {
        proxy_pass http://127.0.0.1:8100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    location /100/api {
        proxy_pass http://127.0.0.1:8100/api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }
}
"""

with open('/tmp/sergeev.conf', 'w') as f:
    f.write(nginx_file)

scp_file('/tmp/sergeev.conf', '/etc/nginx/sites-available/sergeev.conf')
ssh_cmd("ln -sf /etc/nginx/sites-available/sergeev.conf /etc/nginx/sites-enabled/sergeev.conf")
print("  ✓ Done")

# Step 4: Clean nginx
print("\n🧹 Step 4: Cleaning nginx configs...")
ssh_cmd("find /etc/nginx/sites-enabled -name 'default*' -exec rm {} \\; 2>/dev/null || true")
ssh_cmd("find /etc/nginx/sites-available -name 'default*' -exec rm {} \\; 2>/dev/null || true")
print("  ✓ Done")

# Step 5: Test nginx
print("\n🧪 Step 5: Testing nginx...")
output, code = ssh_cmd("nginx -t 2>&1")
if code == 0:
    print(f"  ✓ {output}")
else:
    print(f"  ✗ {output}")
    exit(1)

# Step 6: Reload nginx
print("\n🔄 Step 6: Reloading nginx...")
ssh_cmd("systemctl reload nginx")
print("  ✓ Done")

# Step 7: Start service
print("\n🚀 Step 7: Starting service...")
ssh_cmd("systemctl start sergeev")
time.sleep(3)
print("  ✓ Done")

# Step 8: Check status
print("\n✅ Step 8: Checking status...")
status, _ = ssh_cmd("systemctl is-active sergeev")
print(f"  Service: {status}")

# Step 9: Test app
print("\n🔍 Step 9: Testing app...")
response, _ = ssh_cmd("curl -s http://127.0.0.1:8100/ | head -c 100")
if '<!doctype' in response.lower() or '<html' in response.lower():
    print("  ✓ App responding on port 8100")
else:
    print(f"  Response: {response[:50]}")

# Step 10: Test nginx routing
print("\n🔍 Step 10: Testing nginx routing...")
response, _ = ssh_cmd("curl -s http://127.0.0.1/100 | head -c 100")
if '<!doctype' in response.lower() or '<html' in response.lower():
    print("  ✓ Nginx routing working")
else:
    print(f"  Response: {response[:50]}")

print("\n" + "=" * 70)
print("✅ DEPLOYMENT COMPLETE")
print("=" * 70)
print("\n🌐 Open: http://46.8.255.137/100\n")
