ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

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

RUN LATEST_RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name) && \
    RUNNER_VERSION_NUMBER=$(echo "$LATEST_RUNNER_VERSION" | sed 's/^v//') && \
    curl -L -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/$LATEST_RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION_NUMBER.tar.gz && \
    tar xzf actions-runner.tar.gz && \
    rm -f actions-runner.tar.gz

RUN ./bin/installdependencies.sh

RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN chown -R runner:runner /runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner
WORKDIR /runner

ENTRYPOINT ["/entrypoint.sh"]