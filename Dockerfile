ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}
LABEL org.opencontainers.image.authors="https://github.com/chaddyc"

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN mkdir -p /opt/hostedtoolcache

ARG TARGETARCH
RUN echo "Detected architecture: ${TARGETARCH}"

ENV RUNNER_ARCH=${RUNNER_ARCH}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    tar \
    nano \
    sudo \
    software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
#     chmod +x get-docker.sh && \
#     sh get-docker.sh && \
#     rm get-docker.sh

# WORKDIR /runner

RUN apt-get install ca-certificates && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc

RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && \
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


RUN LATEST_RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name) && \
    RUNNER_VERSION_NUMBER=$(echo "$LATEST_RUNNER_VERSION" | sed 's/^v//') && \
    if [ "${TARGETARCH}" = "amd64" ]; then \
      export RUNNER_ARCH="x64"; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
      export RUNNER_ARCH="arm64"; \
    else \
      echo "Unsupported architecture: ${TARGETARCH}"; exit 1; \
    fi && \
    echo "Downloading https://github.com/actions/runner/releases/download/$LATEST_RUNNER_VERSION/actions-runner-linux-$RUNNER_ARCH-$RUNNER_VERSION_NUMBER.tar.gz" && \
    curl -L -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/$LATEST_RUNNER_VERSION/actions-runner-linux-$RUNNER_ARCH-$RUNNER_VERSION_NUMBER.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm -f actions-runner.tar.gz

RUN ./bin/installdependencies.sh

RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN usermod -aG docker runner

RUN chown -R runner:runner /runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner
WORKDIR /runner

ENTRYPOINT ["/entrypoint.sh"]
