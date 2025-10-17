#!/bin/bash
set -e

# Basic startup cleanup function
startup_cleanup() {
    echo "Performing startup cleanup..."
    
    # Kill any existing SSH agents
    pkill -f ssh-agent || true
    
    # Remove SSH socket files
    find /tmp -name "ssh*" -type s -delete 2>/dev/null || true
    find /tmp -name "agent.*" -type s -delete 2>/dev/null || true
    rm -rf /tmp/ssh-* 2>/dev/null || true
    
    echo "Startup cleanup completed"
}

# Handle Docker socket permissions
if [ -e /var/run/docker.sock ]; then
  sudo chown root:docker /var/run/docker.sock
  sudo chmod 660 /var/run/docker.sock
fi

# Clean up on startup
startup_cleanup

# Ensure the required environment variables are set
if [ -z "$GITHUB_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
  echo "Error: GITHUB_URL and RUNNER_TOKEN environment variables must be set."
  exit 1
fi

# Set default runner name and labels if not provided
RUNNER_NAME=${RUNNER_NAME:-"default-runner"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,default"}

# Configure the GitHub Actions runner with comprehensive cleanup hook
if [ ! -f .runner ]; then
  echo "Configuring runner with name: $RUNNER_NAME and labels: $RUNNER_LABELS"
  
  # Create hooks directory
  mkdir -p .runner-hooks
  
  # Create single comprehensive post-job cleanup hook
  cat > .runner-hooks/post-job.sh << 'EOF'
#!/bin/bash
echo "=== Comprehensive Runner Cleanup Starting ==="

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 1. SSH CLEANUP
log "Step 1: SSH cleanup..."
SSH_PIDS=$(pgrep -u runner ssh-agent 2>/dev/null || true)
if [ ! -z "$SSH_PIDS" ]; then
    log "Killing SSH agents: $SSH_PIDS"
    kill -9 $SSH_PIDS 2>/dev/null || true
fi

# Remove all SSH-related files and directories
find /tmp -user runner -name "ssh*" -delete 2>/dev/null || true
find /tmp -user runner -name "agent.*" -delete 2>/dev/null || true
rm -rf /tmp/ssh-* 2>/dev/null || true
rm -rf ~/.ssh/known_hosts.tmp* 2>/dev/null || true

# Clear SSH environment variables
unset SSH_AUTH_SOCK 2>/dev/null || true
unset SSH_AGENT_PID 2>/dev/null || true

# 2. PROCESS CLEANUP
log "Step 2: Process cleanup..."
# Kill hanging Node.js processes
pkill -u runner node 2>/dev/null || true
pkill -u runner npm 2>/dev/null || true
pkill -u runner npx 2>/dev/null || true

# Kill any other potential hanging processes
pkill -u runner git 2>/dev/null || true
pkill -u runner curl 2>/dev/null || true

# 3. WORKSPACE CLEANUP
log "Step 3: Workspace cleanup..."
# Clean GitHub Actions workspace (be careful not to delete active workspace)
if [ -d "/runner/_work" ]; then
    # Remove old build artifacts but keep current workspace structure
    find /runner/_work -name "node_modules" -type d -mtime +0 -exec rm -rf {} + 2>/dev/null || true
    find /runner/_work -name "dist" -type d -mtime +0 -exec rm -rf {} + 2>/dev/null || true
    find /runner/_work -name "build" -type d -mtime +0 -exec rm -rf {} + 2>/dev/null || true
    find /runner/_work -name ".next" -type d -mtime +0 -exec rm -rf {} + 2>/dev/null || true
    find /runner/_work -name "coverage" -type d -mtime +0 -exec rm -rf {} + 2>/dev/null || true
    
    # Clean log files
    find /runner/_work -name "*.log" -mtime +0 -delete 2>/dev/null || true
    find /runner/_work -name "npm-debug.log*" -delete 2>/dev/null || true
fi

# 4. TEMPORARY FILES CLEANUP
log "Step 4: Temporary files cleanup..."
# GitHub Actions specific temp files
find /tmp -name "*github*" -delete 2>/dev/null || true
find /tmp -name "*actions*" -delete 2>/dev/null || true
find /tmp -name "runner-*" -delete 2>/dev/null || true

# Node.js and npm temp files
find /tmp -name "npm-*" -delete 2>/dev/null || true
find /tmp -name "node-*" -delete 2>/dev/null || true
find /tmp -name ".npm" -type d -exec rm -rf {} + 2>/dev/null || true

# Docker temp files
find /tmp -name "docker-*" -delete 2>/dev/null || true

# General temp files older than 30 minutes
find /tmp -user runner -type f -mmin +30 -delete 2>/dev/null || true

# 5. CACHE CLEANUP
log "Step 5: Cache cleanup..."
# npm cache
npm cache clean --force 2>/dev/null || true

# Node.js cache directories
rm -rf ~/.npm/_cacache 2>/dev/null || true
rm -rf ~/.cache 2>/dev/null || true

# 6. ENVIRONMENT CLEANUP
log "Step 6: Environment cleanup..."
# Clear common environment variables that might persist
unset NODE_ENV 2>/dev/null || true
unset NPM_TOKEN 2>/dev/null || true
unset GITHUB_TOKEN 2>/dev/null || true

# Reset PATH to default (remove any temporary additions)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 7. DOCKER CLEANUP (Optional)
log "Step 7: Docker cleanup..."
# Only uncomment these if you want aggressive Docker cleanup
# docker container prune -f 2>/dev/null || true
# docker volume prune -f 2>/dev/null || true
# docker network prune -f 2>/dev/null || true

# Clean up dangling images only (safer)
docker image prune -f 2>/dev/null || true

# 8. MEMORY CLEANUP
log "Step 8: Memory cleanup..."
# Force garbage collection if possible
sync 2>/dev/null || true

# 9. FINAL STATUS CHECK
log "Step 9: Final status check..."
echo "SSH agents running: $(pgrep -u runner ssh-agent 2>/dev/null | wc -l)"
echo "Node processes running: $(pgrep -u runner node 2>/dev/null | wc -l)"
echo "Temp directory size: $(du -sh /tmp 2>/dev/null | cut -f1)"
echo "Workspace size: $(du -sh /runner/_work 2>/dev/null | cut -f1 || echo 'N/A')"

# 10. LOG ROTATION
log "Step 10: Log cleanup..."
# Clean old runner logs (keep last 10)
if [ -d "/runner/_diag" ]; then
    find /runner/_diag -name "*.log" -type f | sort | head -n -10 | xargs rm -f 2>/dev/null || true
fi

log "=== Comprehensive Runner Cleanup Completed Successfully ==="
EOF
  
  # Make hook executable
  chmod +x .runner-hooks/post-job.sh
  
  echo "Comprehensive cleanup hook created successfully"
  
  # Configure runner
  ./config.sh --url "${GITHUB_URL}" --token "${RUNNER_TOKEN}" --name "${RUNNER_NAME}" --labels "${RUNNER_LABELS}" --unattended --replace
fi

# Enhanced cleanup function for shutdown
cleanup() {
    echo "Shutting down runner..."
    
    # Run the same comprehensive cleanup on shutdown
    if [ -f ".runner-hooks/post-job.sh" ]; then
        ./.runner-hooks/post-job.sh
    fi
    
    # Remove GitHub Actions runner
    ./config.sh remove --unattended || true
    
    exit 0
}

# Trap SIGTERM and SIGINT to allow for cleanup
trap cleanup SIGTERM SIGINT

# Start the runner
echo "Starting GitHub Actions runner with comprehensive cleanup enabled..."
./run.sh
