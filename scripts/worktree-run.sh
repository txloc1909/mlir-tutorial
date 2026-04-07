#!/usr/bin/env bash
# worktree-run.sh — run commands inside a podman container against a git worktree.
#
# Usage:
#   worktree-run.sh <name> [-- <command> [args...]]
#   worktree-run.sh --remove <name>
#
# Environment:
#   WORKTREE_BASE   Base directory for worktrees (default: ~/worktrees/mlir-tutorial)
#   BAZEL_CACHE     Bazel cache directory        (default: ~/.cache/bazel)
#   IMAGE           Container image              (default: ghcr.io/txloc1909/mlir-tutorial-dev:latest)
#
# Examples:
#   worktree-run.sh my-feature -- bazel test //...
#   worktree-run.sh my-feature -- bazel build -c fastbuild //...
#   worktree-run.sh --remove my-feature

set -euo pipefail

WORKTREE_BASE="${WORKTREE_BASE:-$HOME/worktrees/mlir-tutorial}"
BAZEL_CACHE="${BAZEL_CACHE:-$HOME/.cache/bazel}"
IMAGE="${IMAGE:-ghcr.io/txloc1909/mlir-tutorial-dev:latest}"

usage() {
    echo "Usage: $(basename "$0") <name> [-- cmd...]"
    echo "       $(basename "$0") --remove <name>"
    exit 1
}
die() { echo "ERROR: $*" >&2; exit 1; }

[[ $# -ge 1 ]] || usage
REMOVE=false; NAME=""; CMD=()

if [[ "$1" == "--remove" ]]; then
    REMOVE=true
    [[ $# -ge 2 ]] || die "--remove requires a name"
    NAME="$2"
else
    NAME="$1"; shift
    [[ $# -gt 0 && "$1" == "--" ]] && shift
    CMD=("$@")
fi

[[ -n "$NAME" ]] || die "Name must not be empty"
REPO_ROOT="$(git -C "$(dirname "$(realpath "$0")")" rev-parse --show-toplevel)"
WORKTREE_DIR="${WORKTREE_BASE}/${NAME}"

if $REMOVE; then
    if [[ -d "$WORKTREE_DIR" ]]; then
        git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_DIR"
        echo "Removed: $WORKTREE_DIR"
    else
        echo "Not found: $WORKTREE_DIR"
    fi
    exit 0
fi

if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo "Creating worktree '$NAME' at $WORKTREE_DIR ..."
    mkdir -p "$WORKTREE_BASE"
    git -C "$REPO_ROOT" worktree add "$WORKTREE_DIR" HEAD
fi

mkdir -p "$BAZEL_CACHE"

PODMAN_ARGS=(
    run --rm -it
    --security-opt label=disable
    --userns=keep-id
    -v "${WORKTREE_DIR}:/workspace:Z"
    -v "${BAZEL_CACHE}:/home/dev/.cache/bazel:Z"
    -w /workspace
    --user dev
    "$IMAGE"
)

if [[ ${#CMD[@]} -eq 0 ]]; then
    exec podman "${PODMAN_ARGS[@]}" /bin/bash
else
    exec podman "${PODMAN_ARGS[@]}" "${CMD[@]}"
fi
