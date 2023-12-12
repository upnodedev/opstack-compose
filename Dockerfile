# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables to non-interactive (this prevents some prompts)
ENV DEBIAN_FRONTEND=noninteractive

ENV NODE_VERSION 20
ENV GO_VERSION 1.21.2

# Update and install basic dependencies
RUN apt-get update && \
    apt-get install -y git make jq curl wget gettext-base build-essential pkg-config libssl-dev openssl ca-certificates unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Install PNPM
RUN npm install -g pnpm

# Install Go
RUN ARCH=$(dpkg --print-architecture) && echo "Architecture: ${ARCH}" && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz -O go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Install AWS CLI version 2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws

# Define work directory
WORKDIR /app

# Copy the scripts
COPY scripts/clone-repos.sh /app/clone-repos.sh
COPY scripts/utils.sh /app/utils.sh
COPY scripts/prepare.sh /app/prepare.sh
COPY deploy-config.jso[n] /app/deploy-config.json

# Set permissions
RUN chmod +x /app/clone-repos.sh
RUN chmod +x /app/prepare.sh

# Set the clone-repos.sh script as the entry point
ENTRYPOINT ["/app/prepare.sh"]
