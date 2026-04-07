FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ clang \
    cmake ninja-build \
    python3 python3-pip \
    uuid-dev \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# lit for LLVM test runner (matches requirements.txt)
RUN pip3 install --no-cache-dir --break-system-packages lit==18.1.8

# Bazelisk as `bazel` — actual Bazel version is controlled by .bazelversion
RUN curl -fsSL \
    https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
    -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Non-root user (uid=1000) for devpod/distrobox compatibility
RUN groupadd --gid 1000 dev \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash dev

USER dev
WORKDIR /home/dev
