# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

This is an MLIR tutorial project accompanying a
[series of articles](https://jeremykun.com/2023/08/10/mlir-getting-started/)
on building compilers with MLIR. It implements two custom dialects (Poly,
Noisy) and demonstrates passes, lowerings, analysis, and PDLL patterns.

## Build Systems

Two build systems are supported: **Bazel** (primary, covered by articles) and
**CMake** (added at article 10).

### Bazel (Recommended)

Requires [Bazelisk](https://github.com/bazelbuild/bazelisk#installation)
(pinned to Bazel 8.3.1 via `.bazelversion`).

```bash
bazel build //...
bazel test //...

# Fast build (no optimizations)
bazel build -c fastbuild //...
bazel test -c fastbuild //...

# Single test
bazel test //tests:test_name
```

### CMake

Requires building LLVM/MLIR from the `externals/llvm-project` submodule first:

```bash
# 1. Build LLVM/MLIR
cd externals/llvm-project && mkdir build && cd build
cmake ../llvm -G Ninja -DLLVM_ENABLE_PROJECTS=mlir \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_INSTALL_UTILS=ON
cmake --build . --target check-mlir

# 2. Build tutorial
mkdir build-ninja && cd build-ninja
cmake -G Ninja .. \
  -DLLVM_DIR=externals/llvm-project/build/lib/cmake/llvm \
  -DMLIR_DIR=externals/llvm-project/build/lib/cmake/mlir \
  -DBUILD_DEPS=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Debug

# 3. Run tests
cmake --build . --target tutorial-opt
cmake --build . --target check-mlir-tutorial
```

## Architecture

### Source Layout

- **`lib/Dialect/`** — Custom dialect definitions
  - `Poly/` — Polynomial arithmetic dialect (the main tutorial dialect)
  - `Noisy/` — Noisy computation dialect (articles 12-13)
- **`lib/Transform/`** — Standalone transformation passes
  - `Affine/` — `AffineFullUnroll`: complete affine loop unrolling
  - `Arith/` — `MulToAdd`: multiply-by-constant to add-shifts;
    `MulToAddPdll`: same via PDLL
  - `Noisy/` — `ReduceNoiseOptimizer`: noise reduction pass using dataflow
    analysis
- **`lib/Conversion/`** — Dialect conversion passes
  - `PolyToStandard/` — Lowers Poly ops to arith/tensor/polynomial standard
    dialect ops
- **`lib/Analysis/`** — Dataflow analyses
  - `ReduceNoiseAnalysis/` — Dataflow analysis identifying noise optimization
    opportunities
- **`tools/tutorial-opt.cpp`** — Main driver binary (analogous to `mlir-opt`),
  registers all custom dialects/passes and defines the `poly-to-llvm` pipeline
- **`tests/`** — Lit test files (`.mlir`) verified with FileCheck

### Key Concepts

**Poly Dialect**: Defines a polynomial type `poly.poly<N>` with ops:
`poly.add`, `poly.sub`, `poly.mul`, `poly.constant`, `poly.from_tensor`,
`poly.to_tensor`, `poly.eval`. Defined via TableGen (`.td` files) with traits,
verifiers, folders, and canonicalization patterns.

**Noisy Dialect**: Models computations with configurable noise levels. Used for
the dataflow analysis article.

**Lowering pipeline**: Poly → standard dialects (arith, tensor, polynomial) →
LLVM IR, registered as the `poly-to-llvm` pipeline in `tutorial-opt`.

**Test format**: Each `.mlir` file in `tests/` is a Lit test using
`// RUN: tutorial-opt %s ...` and `// CHECK:` directives.

### Dependency Management (Bazel)

LLVM/MLIR is pulled via a custom Bazel module extension in `extensions.bzl`
(pinned to a specific LLVM commit). Other dependencies (abseil, or-tools,
protobuf, eigen) come from the Bazel Central Registry via `MODULE.bazel`.

To update the LLVM commit, change the `commit` field in `extensions.bzl`.
