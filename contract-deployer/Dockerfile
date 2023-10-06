# Start with the official Ubuntu image as a base
FROM ubuntu:22.04

# Set environment variables to non-interactive (this prevents some prompts)
ENV DEBIAN_FRONTEND=non-interactive

# Software versions
ENV NODE_VERSION 18.x
ENV GO_VERSION 1.21.2

# Update the system and install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    openssl \
    python3 \
    python3-pip \
    aria2 \
    zstd

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs

# Install pnpm
RUN npm install -g pnpm

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Foundry using the provided command
RUN curl -L https://foundry.paradigm.xyz | bash

# Install go
RUN ARCH=$(dpkg --print-architecture) wget https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz -O go.tar.gz
RUN tar -C /usr/local -xzf go.tar.gz
RUN rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
