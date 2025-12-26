# --- Build Stage ---
FROM rust:latest AS builder

# Use China mirrors for Rust toolchain and crates
ENV RUSTUP_DIST_SERVER=https://rsproxy.cn
ENV RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

# Install nightly toolchain (required for edition2024)
RUN rustup install nightly-2025-04-06 && \
    rustup default nightly-2025-04-06

# Configure cargo to use China mirror (rsproxy.cn)
RUN mkdir -p ~/.cargo && \
    echo '[source.crates-io]' > ~/.cargo/config.toml && \
    echo 'replace-with = "rsproxy-sparse"' >> ~/.cargo/config.toml && \
    echo '[source.rsproxy-sparse]' >> ~/.cargo/config.toml && \
    echo 'registry = "sparse+https://rsproxy.cn/index/"' >> ~/.cargo/config.toml

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy entire project
COPY . .

# Build release binary
WORKDIR /app/clients/cli
RUN cargo build --release

# --- Runtime Stage ---
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary with disguised name (looks like a normal backend service)
COPY --from=builder /app/clients/cli/target/release/nexus-network ./node-worker

ENTRYPOINT ["./node-worker"]
CMD ["--help"]
