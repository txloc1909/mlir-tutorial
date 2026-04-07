FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ clang \
    cmake ninja-build \
    python3 python3-pip \
    uuid-dev \
    zlib1g-dev \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# lit for LLVM test runner (matches requirements.txt)
RUN pip3 install --no-cache-dir --break-system-packages lit==18.1.8

# Bazelisk as `bazel` — actual Bazel version is controlled by .bazelversion
RUN curl -fsSL \
    https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
    -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Non-root user (uid=1000) for devpod/distrobox compatibility.
# ubuntu:24.04 ships an 'ubuntu' user at uid/gid 1000 — rename it instead
# of creating a new one to avoid GID/UID conflicts.
RUN usermod -l dev -d /home/dev -m -s /bin/bash ubuntu \
    && groupmod -n dev ubuntu

USER dev
WORKDIR /home/dev
