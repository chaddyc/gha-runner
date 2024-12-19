#!/bin/bash
set -e

# Ensure the required environment variables are set
if [ -z "$GITHUB_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
  echo "Error: GITHUB_URL and RUNNER_TOKEN environment variables must be set."
  exit 1
fi

# Configure the GitHub Actions runner
if [ ! -f .runner ]; then
  ./config.sh --url "${GITHUB_URL}" --token "${RUNNER_TOKEN}" --name "${RUNNER_NAME}" --unattended --replace
fi

RUNNER_NAME=${RUNNER_NAME:-"default-runner"}

# Trap SIGTERM and SIGINT to allow for cleanup
trap './config.sh remove --unattended && exit 0' SIGTERM SIGINT

# Start the runner
./run.sh
