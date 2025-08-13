# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
- `cargo build` - Build the project
- `cargo test` - Run tests (use nextest for better experience: `cargo nextest run`)
- `cargo nextest run` - Recommended test runner (install with `cargo install cargo-nextest`)
- `cargo run -- <args>` - Run the development version of uv (e.g., `cargo run -- venv`)
- `cargo run --bin uv-dev --features dev -- generate-json-schema` - Update JSON schema if tests fail due to schema mismatches
- `cargo insta review` - Review snapshot test changes (install with `cargo install cargo-insta`)
- `cargo fmt` - Format code
- `cargo clippy` - Run linting checks

### Testing Infrastructure
- Uses `nextest` for running tests with better output and parallelization
- Snapshot testing with `insta` crate - tests create `.snap` files for output verification
- Use `uv_snapshot!` macro in tests for command output snapshots
- Tests are located in `crates/uv/tests/it/` for integration tests
- Unit tests are co-located with source code

### Python Installation for Tests
- `cargo run python install` - Install required Python versions for testing
- Storage directory configurable with `UV_PYTHON_INSTALL_DIR` (absolute path)

### Code Generation
- `cargo run --bin uv-dev --features dev -- generate-all` - Update auto-generated documentation and schemas
- JSON schema lives at `uv.schema.json`

### Documentation
```bash
# Build and serve docs locally
uvx --with-requirements docs/requirements.txt -- mkdocs serve -f mkdocs.public.yml
```

### Profiling and Performance
- Use `profiling` profile: `cargo build --profile profiling`
- Tracing support available with feature flag
- Environment variables for debugging:
  - `RUST_LOG=trace` - Enable trace-level logging
  - `TRACING_DURATIONS_FILE=target/traces/file.ndjson` - Export timing traces

## Architecture Overview

### Core Components
- **uv**: Main CLI binary and command orchestration (`crates/uv/`)
- **uv-cli**: Command-line interface definitions and argument parsing
- **uv-resolver**: Dependency resolution engine using PubGrub algorithm
- **uv-python**: Python installation management and discovery
- **uv-installer**: Package installation logic
- **uv-client**: HTTP client for PyPI and package registry interactions

### Key Architecture Patterns
- **Modular crate structure**: 50+ specialized crates for different functionality
- **Async/tokio runtime**: All I/O operations are async
- **Configuration system**: Hierarchical config from CLI args -> pyproject.toml -> uv.toml
- **Workspace-aware**: Supports Cargo-style workspaces for Python projects
- **Universal lockfiles**: Cross-platform dependency locking

### Important Subsystems
- **Distribution handling**: `uv-distribution*` crates handle wheel/sdist processing
- **Platform support**: `uv-platform*` crates handle platform-specific logic
- **Authentication**: `uv-auth` handles keyring and credential management
- **Caching**: `uv-cache*` crates provide sophisticated dependency caching
- **Virtual environments**: `uv-virtualenv` manages Python virtual environments

### Build System
- Rust workspace with 50+ crates
- Uses maturin for Python package building (`pyproject.toml`)
- Custom build profiles: `profiling`, `minimal-size`, `dist`
- Supports multiple architectures and platforms

### Testing Strategy
- Integration tests in `crates/uv/tests/it/`
- Snapshot testing for CLI output verification using `uv_snapshot!` macro
- Real ecosystem testing against popular packages in `ecosystem/`
- Performance regression testing with benchmark suite
- Run specific test: `cargo test --package <package> --test <test> -- <test_name> -- --exact`

### Development Workflow Patterns
- Commands are defined in `crates/uv-cli/src/lib.rs` and implemented in `crates/uv/src/commands/`
- Settings resolution follows hierarchy: CLI args -> workspace config -> user config -> system config
- Each major command has its own settings struct that combines all configuration sources
- Error handling uses `anyhow` with `miette` for pretty error display
- Extensive use of `tracing` for debugging and instrumentation

### Entry Point Flow
1. CLI parsing in `crates/uv-cli/`
2. Settings resolution from multiple config sources
3. Command dispatch in `crates/uv/src/lib.rs`
4. Command implementation in `crates/uv/src/commands/`
5. Core logic in specialized crates (resolver, installer, etc.)

### Key File Locations
- Main CLI entry point: `crates/uv/src/lib.rs:62` (`run` function)
- Command definitions: `crates/uv-cli/src/lib.rs`
- Command implementations: `crates/uv/src/commands/`
- Settings resolution: `crates/uv/src/settings.rs`
- Test utilities: `crates/uv/tests/it/common/mod.rs`