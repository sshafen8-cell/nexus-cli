# --- Build Stage ---
FROM rust:latest AS builder

# Install nightly toolchain (required for edition2024)
RUN rustup install nightly-2025-04-06 && \
    rustup default nightly-2025-04-06

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

# Copy binary from builder
COPY --from=builder /app/clients/cli/target/release/nexus-network .

ENTRYPOINT ["./nexus-network"]
CMD ["--help"]
