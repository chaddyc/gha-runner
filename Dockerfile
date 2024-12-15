# Use build argument for Ubuntu version and architecture
ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}
LABEL org.opencontainers.image.authors="https://github.com/chaddyc"

# Set build-time architecture (amd64 or arm64)
ARG TARGETARCH
RUN echo "Detected architecture: ${TARGETARCH}"

# Map TARGETARCH to the appropriate format for GitHub Actions Runner
RUN if [ "${TARGETARCH}" = "amd64" ]; then \
      RUNNER_ARCH="x64"; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
      RUNNER_ARCH="arm64"; \
    else \
      echo "Unsupported architecture: ${TARGETARCH}"; exit 1; \
    fi && \
    echo "Mapped architecture: ${RUNNER_ARCH}"


# Set RUNNER_ARCH as an environment variable for subsequent steps
ENV RUNNER_ARCH=${RUNNER_ARCH}

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    tar \
    sudo \
    software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /runner

# Download the latest GitHub Actions Runner based on architecture
RUN LATEST_RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name) && \
    RUNNER_VERSION_NUMBER=$(echo "$LATEST_RUNNER_VERSION" | sed 's/^v//') && \
    curl -L -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/$LATEST_RUNNER_VERSION/actions-runner-linux-${RUNNER_ARCH}-$RUNNER_VERSION_NUMBER.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm -f actions-runner.tar.gz

# Install dependencies for the runner
RUN ./bin/installdependencies.sh

# Create a 'runner' user and set permissions
RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN chown -R runner:runner /runner

# Copy entrypoint script and set permissions
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to the 'runner' user
USER runner
WORKDIR /runner

ENTRYPOINT ["/entrypoint.sh"]
