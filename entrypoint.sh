#!/bin/bash
set -e

# Clean up any existing SSH agents and sockets on startup
cleanup_existing_ssh() {
    echo "Cleaning up existing SSH agents and sockets..."
    
    # Kill any existing SSH agents
    pkill -f ssh-agent || true
    
    # Remove any existing SSH socket files
    find /tmp -name "ssh*" -type s -delete 2>/dev/null || true
    find /tmp -name "agent.*" -type s -delete 2>/dev/null || true
    
    echo "SSH cleanup completed"
}

# Handle Docker socket permissions
if [ -e /var/run/docker.sock ]; then
  sudo chown root:docker /var/run/docker.sock
  sudo chmod 660 /var/run/docker.sock
fi

# Clean up existing SSH resources
cleanup_existing_ssh

# Ensure the required environment variables are set
if [ -z "$GITHUB_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
  echo "Error: GITHUB_URL and RUNNER_TOKEN environment variables must be set."
  exit 1
fi

# Set default runner name and labels if not provided
RUNNER_NAME=${RUNNER_NAME:-"default-runner"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,default"}

# Configure the GitHub Actions runner
if [ ! -f .runner ]; then
  echo "Configuring runner with name: $RUNNER_NAME and labels: $RUNNER_LABELS"
  ./config.sh --url "${GITHUB_URL}" --token "${RUNNER_TOKEN}" --name "${RUNNER_NAME}" --labels "${RUNNER_LABELS}" --unattended --replace
fi

# Trap SIGTERM and SIGINT to allow for cleanup
trap './config.sh remove --unattended && exit 0' SIGTERM SIGINT

# Start the runner
./run.sh
