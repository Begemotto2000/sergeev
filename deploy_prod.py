#!/usr/bin/env python3
import subprocess
import time
import sys

HOST = "46.8.255.137"
USER = "root"
PASS = "k8hSaZ2XL37x"

def ssh_cmd(cmd):
    """Execute SSH command"""
    full_cmd = f"sshpass -p '{PASS}' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {USER}@{HOST} \"{cmd}\""
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=60)
    return result.stdout.strip(), result.stderr.strip(), result.returncode

def scp_file(src, dst):
    """Copy file via SCP"""
    full_cmd = f"sshpass -p '{PASS}' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r {src} {USER}@{HOST}:{dst}"
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=120)
    return result.returncode == 0

print("=" * 70)
print("PRODUCTION DEPLOYMENT")
print("=" * 70)

# Step 1: Stop service
print("\n🛑 Step 1: Stopping service...")
ssh_cmd("systemctl stop sergeev; pkill -9 npm || true; sleep 2")
print("  ✓ Done")

# Step 2: Update Node.js
print("\n📥 Step 2: Updating Node.js to v22...")
stdout, stderr, code = ssh_cmd("curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs 2>&1 | tail -5")
print("  ✓ Done")

# Step 3: Verify versions
print("\n✅ Step 3: Verifying versions...")
node_v, _, _ = ssh_cmd("node --version")
npm_v, _, _ = ssh_cmd("npm --version")
print(f"  Node: {node_v}")
print(f"  npm: {npm_v}")

# Step 4: Clean
print("\n🧹 Step 4: Cleaning...")
ssh_cmd("cd /opt/sergeev/app && rm -rf dist node_modules package-lock.json")
print("  ✓ Done")

# Step 5: Copy dist
print("\n📦 Step 5: Copying dist...")
if scp_file("/home/ubuntu/sergeev_digitization_system/dist", "/opt/sergeev/app/"):
    print("  ✓ dist copied")
else:
    print("  ✗ Failed to copy dist")
    sys.exit(1)

# Step 6: Copy node_modules
print("\n📦 Step 6: Copying node_modules...")
print("  Creating tar...")
subprocess.run("cd /home/ubuntu/sergeev_digitization_system && tar czf /tmp/nm.tar.gz node_modules", shell=True, timeout=60)
print("  Uploading...")
if scp_file("/tmp/nm.tar.gz", "/opt/sergeev/app/"):
    print("  Extracting...")
    ssh_cmd("cd /opt/sergeev/app && tar xzf nm.tar.gz && rm nm.tar.gz")
    print("  ✓ node_modules copied")
else:
    print("  ✗ Failed")
    sys.exit(1)

# Step 7: Verify
print("\n✅ Step 7: Verifying...")
stdout, _, _ = ssh_cmd("ls -lh /opt/sergeev/app/dist/index.js | awk '{print $5}'")
print(f"  dist/index.js: {stdout}")

# Step 8: Start service
print("\n🚀 Step 8: Starting service...")
ssh_cmd("systemctl start sergeev && sleep 3")
print("  ✓ Done")

# Step 9: Check status
print("\n✅ Step 9: Checking status...")
stdout, _, _ = ssh_cmd("systemctl is-active sergeev")
print(f"  Service: {stdout}")

# Step 10: Test
print("\n🔍 Step 10: Testing application...")
stdout, _, _ = ssh_cmd("curl -s http://localhost:3000/ | head -c 100")
if "<!doctype" in stdout.lower() or "<html" in stdout.lower():
    print("  ✓ Application responding")
else:
    print(f"  Response: {stdout[:50]}")

print("\n" + "=" * 70)
print("✅ DEPLOYMENT COMPLETE")
print("=" * 70)
print("\n🌐 http://46.8.255.137/100\n")
