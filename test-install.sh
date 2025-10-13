#!/bin/bash

# Test script to validate the installation script in a Docker container

echo "=== Testing Sewercide CTF Installation in Docker ==="

# Build test container
docker build -t sewercide-test -f- . <<'EOF'
FROM ubuntu:24.04

# Copy setup files
COPY src/ /tmp/sewercide-setup/

# Run installation
RUN bash /tmp/sewercide-setup/install.sh

# Expose ports
EXPOSE 9999 22

# Keep container running for testing
CMD ["tail", "-f", "/dev/null"]
EOF

echo ""
echo "=== Starting test container ==="
docker run -d --name sewercide-test -p 9999:9999 -p 2222:22 sewercide-test

echo ""
echo "=== Waiting for services to start ==="
sleep 5

echo ""
echo "=== Checking services status ==="
docker exec sewercide-test systemctl status nginx --no-pager || echo "Nginx status check failed"
docker exec sewercide-test systemctl status ssh --no-pager || echo "SSH status check failed"

echo ""
echo "=== Checking flag file ==="
docker exec sewercide-test bash -c "ls -la /etc/flag_*.txt"

echo ""
echo "=== Checking webmaster SSH key ==="
docker exec sewercide-test bash -c "ls -la /home/webmaster/.ssh/"

echo ""
echo "=== Testing web application ==="
curl -s http://localhost:9999/ | head -n 20

echo ""
echo "=== Test container is running ==="
echo "Web: http://localhost:9999"
echo "SSH: ssh -p 2222 webmaster@localhost (requires key)"
echo ""
echo "To interact with container: docker exec -it sewercide-test bash"
echo "To stop and remove: docker stop sewercide-test && docker rm sewercide-test"
