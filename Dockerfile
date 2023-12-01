# Use Ubuntu as the base image
FROM ubuntu:22.04

ENV NODE_VERSION 20
ENV GO_VERSION 1.21.2

# Update and install basic dependencies
RUN apt-get update && \
    apt-get install -y git make jq curl wget direnv build-essential pkg-config libssl-dev openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js using NVM and pnpm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash && \
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && \
    npm install -g pnpm

# Install Go
RUN ARCH=$(dpkg --print-architecture) && echo "Architecture: ${ARCH}" && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz -O go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    export PATH="$HOME/.foundry/bin:$PATH" && \
    foundryup

# Define work directory
WORKDIR /app

# Copy the clone script
COPY clone-repos.sh /clone-repos.sh
RUN chmod +x /clone-repos.sh

# Set the startup script as the entry point
ENTRYPOINT ["/clone-repos.sh"]

# Keep the container running
CMD tail -f /dev/null
